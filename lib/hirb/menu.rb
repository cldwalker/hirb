module Hirb
  # This class provides a menu using Hirb's table helpers by default to display choices.
  # Menu choices (syntax at Hirb::Util.choose_from_array) refer to rows. However, when in
  # two_d mode, choices refer to specific cells by appending a ':field' to a choice.
  # A field name can be an abbreviated. Menus can also have an action mode, which turns the
  # menu prompt into a commandline that executes the choices as arguments and uses methods as
  # actions/commands.
  class Menu
    class Error < StandardError; end

    # Detects valid choices and optional field/column
    CHOSEN_REGEXP = /^(\d([^:]+)?|\*)(?::)?(\S+)?/
    CHOSEN_ARG = '%s'
    DIRECTIONS = "Specify individual choices (4,7), range of choices (1-3) or all choices (*)."


    # This method will return an array unless it's exited by simply pressing return, which returns nil.
    # If given a block, the block will yield if and with any menu items are chosen.
    # All options except for the ones below are passed to render the menu.
    #
    # ==== Options:
    # [*:helper_class*]  Helper class to render menu. Helper class is expected to implement numbering given a :number option.
    #                    To use a very basic menu, set this to false. Defaults to Hirb::Helpers::AutoTable.
    # [*:prompt*]  String for menu prompt. Defaults to "Choose: ".
    # [*:ask*] Always ask for input, even if there is only one choice. Default is true.
    # [*:directions*] Display directions before prompt. Default is true.
    # [*:readline*] Use readline to get user input if available. Input strings are added to readline history. Default is false.
    # [*:two_d*] Turn menu into a 2 dimensional (2D) menu by allowing user to pick values from table cells. Default is false.
    # [*:default_field*] Default field for a 2D menu. Defaults to first field in a table.
    # [*:action*] Turn menu into an action menu by letting user pass menu choices as an argument to a method/command.
    #             A menu choice's place amongst other arguments is preserved. Default is false.
    # [*:multi_action*] Execute action menu multiple times iterating over the menu choices. Default is false.
    # [*:action_object*] Object that takes method/command calls. Default is main.
    # [*:command*] Default method/command to call when no command given.
    # [*:reopen*] Reopens $stdin with given file or with /dev/tty when set to true. Use when
    #             $stdin is already reading in piped data.
    # Examples:
    #     >> extend Hirb::Console
    #     => self
    #     >> menu [1,2,3], :prompt=> "So many choices, so little time: "
    #     >> menu [{:a=>1, :b=>2}, {:a=>3, :b=>4}], :fields=>[:a,b], :two_d=>true)
    def self.render(output, options={}, &block)
      new(options).render(output, &block)
    rescue Error=>e
      $stderr.puts "Error: #{e.message}"
    end

    #:stopdoc:
    def initialize(options={})
      @options = {:helper_class=>Hirb::Helpers::AutoTable, :prompt=>"Choose: ", :ask=>true,
        :directions=>true}.merge options
      @options[:reopen] = '/dev/tty' if @options[:reopen] == true
    end

    def render(output, &block)
      @output = Array(output)
      return [] if @output.size.zero?
      chosen = choose_from_menu
      block.call(chosen) if block && chosen.size > 0
      @options[:action] ? execute_action(chosen) : chosen
    end

    def get_input
      prompt = pre_prompt + @options[:prompt]
      prompt = DIRECTIONS+"\n"+prompt if @options[:directions]
      $stdin.reopen @options[:reopen] if @options[:reopen]

      if @options[:readline] && readline_loads?
        get_readline_input(prompt)
      else
        print prompt
        $stdin.gets.chomp.strip
      end
    end

    def get_readline_input(prompt)
      input = Readline.readline prompt
      Readline::HISTORY << input
      input
    end

    def pre_prompt
      prompt = ''
      prompt << "Default field: #{default_field}\n" if @options[:two_d] && default_field
      prompt << "Default command: #{@options[:command]}\n" if @options[:action] && @options[:command]
      prompt
    end

    def choose_from_menu
      return unasked_choice if @output.size == 1 && !@options[:ask]

      if (Util.any_const_get(@options[:helper_class]))
        View.render_output(@output, :class=>@options[:helper_class], :options=>@options.merge(:number=>true))
      else
        @output.each_with_index {|e,i| puts "#{i+1}: #{e}" }
      end

      parse_input get_input
    end

    def unasked_choice
      return @output unless @options[:action]
      raise(Error, "Default command and field required for unasked action menu") unless default_field && @options[:command]
      @new_args = [@options[:command], CHOSEN_ARG]
      map_tokens([[@output, default_field]])
    end

    def execute_action(chosen)
      return nil if chosen.size.zero?
      if @options[:multi_action]
        chosen.each {|e| invoke command, add_chosen_to_args(e) }
      else
        invoke command, add_chosen_to_args(chosen)
      end
    end

    def invoke(cmd, args)
      action_object.send(cmd, *args)
    end

    def parse_input(input)
      if (@options[:two_d] || @options[:action])
        tokens = input_to_tokens(input)
        map_tokens(tokens)
      else
        Util.choose_from_array(@output, input)
      end
    end

    def map_tokens(tokens)
      values = if return_cell_values?
        @output[0].is_a?(Hash) ?
          tokens.map {|arr,f| arr.map {|e| e[f]} } :
          tokens.map {|arr,f|
            arr.map {|e| e.is_a?(Array) && f.is_a?(Integer) ? e[f] : e.send(f) }
          }
      else
        tokens.map {|arr, f| arr[0] }
      end
      values.flatten
    end

    def return_cell_values?
      @options[:two_d]
    end

    def input_to_tokens(input)
      @new_args = []
      tokens = (@args = split_input_args(input)).map {|word| parse_word(word) }.compact
      cleanup_new_args
      tokens
    end

    def parse_word(word)
      if word[CHOSEN_REGEXP]
        @new_args << CHOSEN_ARG
        field = $3 ? unalias_field($3) : default_field ||
          raise(Error, "No default field/column found. Fields must be explicitly picked.")

        token = Util.choose_from_array(@output, word)
        token = [token] if word[/\*|-|\.\.|,/] && !return_cell_values?
        [token, field]
      else
        @new_args << word
        nil
      end
    end

    def cleanup_new_args
      if @new_args.all? {|e| e == CHOSEN_ARG }
        @new_args = [CHOSEN_ARG]
      else
        i = @new_args.index(CHOSEN_ARG) || raise(Error, "No rows chosen")
        @new_args.delete(CHOSEN_ARG)
        @new_args.insert(i, CHOSEN_ARG)
      end
    end

    def add_chosen_to_args(items)
      args = @new_args.dup
      args[args.index(CHOSEN_ARG)] = items
      args
    end

    def command
      @command ||= begin
        cmd = (@new_args == [CHOSEN_ARG]) ? nil : @new_args.shift
        cmd ||= @options[:command] || raise(Error, "No command given for action menu")
      end
    end

    def action_object
      @options[:action_object] || eval("self", TOPLEVEL_BINDING)
    end

    def split_input_args(input)
      input.split(/\s+/)
    end

    def default_field
      @default_field ||= @options[:default_field] || fields[0]
    end

    # Has to be called after displaying menu
    def fields
      @fields ||= @options[:fields] || (@options[:ask] && table_helper_class? && Helpers::Table.last_table ?
        Helpers::Table.last_table.fields[1..-1] : [])
    end

    def table_helper_class?
      @options[:helper_class].is_a?(Class) && @options[:helper_class] < Helpers::Table
    end

    def unalias_field(field)
      fields.sort_by {|e| e.to_s }.find {|e| e.to_s[/^#{field}/] } || raise(Error, "Invalid field '#{field}'")
    end

    def readline_loads?
      require 'readline'
      true
    rescue LoadError
      false
    end
    #:startdoc:
  end
end
