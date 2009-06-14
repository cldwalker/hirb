module Hirb
  class Pager
    class<<self
      def command_pager(output, options={})
        if options[:pager_command] 
          basic_pager(output) if pager_command(options[:pager_command])
          return
        elsif pager_command
          basic_pager(output)
        end
      end

      def pager_command(*commands)
        @pager_command ||= begin
          commands = [ENV['PAGER'], 'less', 'more', 'pager'] if commands.empty?
          commands.compact.uniq.find {|e| command_exists?(e) }
        end
      end

      def default_pager(output, options={})
        pager = new(options[:width], options[:height])
        while pager.activated_by?(output, options[:inspect])
          puts pager.slice!(output, options[:inspect])
          return unless continue_paging?
        end
        puts output
        puts "=== Pager finished. ==="
      end

      private
      def command_exists?(command)
        ENV['PATH'].split(File::PATH_SEPARATOR).any? {|d| File.exists? File.join(d, command) }
      end

      def basic_pager(output)
        pager = IO.popen(pager_command, "w")
        begin
          save_stdout = STDOUT.clone
          STDOUT.reopen(pager)
          puts obj
        ensure
         STDOUT.reopen(save_stdout)
         save_stdout.close
         pager.close
        end
      end

      def continue_paging?
        puts "=== Press enter/return to continue or q to quit: ==="
        !$stdin.gets.chomp[/q/i]
      end
      
    end

    attr_accessor :width, :height

    def initialize(width, height)
      resize(width, height)
    end

    def page(string, inspect_mode)
      if self.class.pager_command
        self.class.command_pager(string)
      else
        puts "Using default pager since no valid pager commmand is set. Set one with :pager_command"
        self.class.default_pager(string, :width=>@width, :height=>@height, :inspect=>inspect_mode)
      end
    end

    # note: the last line will be cut early in inspect_mode if the correct height + width aren't set
    def slice!(output, inspect_mode=false)
      if inspect_mode
        sliced_output = output.slice(0,@width * @height)
        output.replace output.slice(@width * @height..-1)
        sliced_output
      else
        # could use output.scan(/[^\n]*\n?/) instead of split
        sliced_output = output.split("\n").slice(0,@height).join("\n")
        output.replace output.split("\n").slice(@height..-1).join("\n")
        sliced_output
      end
    end

    def activated_by?(string_to_page, inspect_mode=false)
      inspect_mode ? (string_to_page.size > @height * @width) : (string_to_page.count("\n") > @height)
    end

    # these environment variables should work for *nix, others should use highline's Highline::SystemExtensions.terminal_size
    def resize(width, height)
      @width = width || (ENV['COLUMNS'] =~ /^\d+$/ ? ENV['COLUMNS'].to_i : 150)
      @height = height || (ENV['LINES'] =~ /^\d+$/ ? ENV['LINES'].to_i : 50)
    end
  end
end
