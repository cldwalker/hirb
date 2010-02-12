module Hirb
  # This class provides a selection menu using Hirb's table helpers by default to display choices.
  class Menu
    class Error < StandardError; end

    # Detects valid choices and optional field/column
    CHOSEN_REGEXP = /^(\d([^:]+)?)(?::)?(\S+)?/

    # Menu which asks to select from the given array and returns the selected menu items as an array. See Hirb::Util.choose_from_array
    # for the syntax for specifying selections. If menu is given a block, the block will yield if any menu items are chosen.
    # All options except for the ones below are passed to render the menu.
    #
    # ==== Options:
    # [:helper_class]  Helper class to render menu. Helper class is expected to implement numbering given a :number option.
    #                  To use a very basic menu, set this to false. Defaults to Hirb::Helpers::AutoTable.
    # [:prompt]  String for menu prompt. Defaults to "Choose: ".
    # [:validate_one] Validates that only one item in array is chosen and returns just that item. Default is false.
    # [:ask] Always ask for input, even if there is only one choice. Default is true.
    # [:directions] Display directions before prompt. Default is true.
    # [:return_input] Returns input string without selecting menu items. Default is false
    # [:readline] Uses readline to get user input if available. Input strings are added to readline history. Default is false.
    # Examples:
    #     extend Hirb::Console
    #     menu([1,2,3], :fields=>[:field1, :field2], :validate_one=>true)
    #     menu([1,2,3], :helper_class=>Hirb::Helpers::Table)
    def self.render(output, options={}, &block)
      new(options).render(output, &block)
    rescue Error=>e
      $stderr.puts "Error: #{e.message}"
    end

    #:stopdoc:
    def initialize(options={})
      default_options = {:helper_class=>Hirb::Helpers::AutoTable, :prompt=>"Choose #{options[:validate_one] ? 'one' : ''}: ",
        :ask=>true, :directions=>true}
      @options = default_options.merge(options)
    end

    def render(output, &block)
      return (@options[:return_input] ? '' : []) if (output = Array(output)).size.zero?
      chosen = choose_from_menu(output)
      block.call(chosen) if block && Array(chosen).size > 0
      @options[:execute] ? execute(chosen) : chosen
    end

    def get_input
      directions = "Specify individual choices (4,7), range of choices (1-3) or all choices (*).\n"
      prompt = @options[:directions] ? directions+@options[:prompt] : @options[:prompt]
      if @options[:readline] && readline_loads?
        input = Readline.readline prompt
        Readline::HISTORY << input
        input
      else
        print prompt
        $stdin.gets.chomp.strip
      end
    end

    def choose_from_menu(output)
      return (@options[:return_input] ? '1' : output) if output.size == 1 && !@options[:ask]
      if (helper_class = Util.any_const_get(@options[:helper_class]))
        View.render_output(output, :class=>@options[:helper_class], :options=>@options.merge(:number=>true))
      else
        output.each_with_index {|e,i| puts "#{i+1}: #{e}" }
      end

      input = get_input
      return input if @options[:return_input]
      chosen = parse_input(output, input)

      if @options[:validate_one]
        if chosen.size != 1
          $stderr.puts "Choose one. You chose #{chosen.size} items."
          return nil
        else
          return chosen[0]
        end
      end
      chosen
    end

    def execute(chosen)
      cmd = get_command
      args = add_chosen_to_args chosen
      action_object.send(cmd, *args)
    end

    def parse_input(output, input)
      @options[:two_d] ? parse_2d_input(output, input) : @options[:execute] ?
        input_to_template(output, input).map {|e| e[0] }.flatten :
        Util.choose_from_array(output, input)
    end

    def input_to_template(output, input)
      template = []
      tokens = split_input_args(input).map {|word|
        if word[CHOSEN_REGEXP]
          template << '%s'
          field = $3 ? unalias_field($3) : default_field ||
            raise(Error, "No default field/column found. Fields must be explicitly picked.")
          [Util.choose_from_array(output, word), field ]
        else
          template << word
          nil
        end
      }.compact
      @template = get_template(template)
      tokens
    end

    def parse_2d_input(output, input)
      tokens = input_to_template(output, input)
      output[0].is_a?(Hash) ? tokens.map {|arr,f| arr.map {|e| e[f]} }.flatten :
        tokens.map {|arr,f| arr.map {|e| e.send(f) } }.flatten
    end

    def get_template(template)
      template.all? {|e| e == '%s' } ? ['%s'] : begin
        i = template.index('%s') || raise(Error, "No rows chosen")
        template.delete('%s')
        template.insert(i, '%s')
        template
      end
    end

    def add_chosen_to_args(items)
      args = @template.dup
      args[args.index('%s')] = items
      args
    end

    def get_command
      cmd = @template.shift || @options[:default_command]
      raise Error, "No command given" if [nil, '%s'].include?(cmd)
      cmd
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
      @fields ||= begin
        @options[:fields] || ((@options[:helper_class] < Helpers::Table || @options[:helper_class] == Helpers::AutoTable) &&
          Helpers::Table.last_table ? Helpers::Table.last_table.fields[1..-1] : [])
      end
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