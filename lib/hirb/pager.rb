module Hirb
  # This class provides class methods for paging and an object which can conditionally page given a terminal size that is exceeded.
  class Pager
    class<<self
      # Pages using a configured or detected shell command.
      def command_pager(output, options={})
        basic_pager(output) if valid_pager_command?(options[:pager_command])
      end

      def pager_command(*commands) #:nodoc:
        @pager_command = (!@pager_command.nil? && commands.empty?) ? @pager_command : 
          begin
            commands = [ENV['PAGER'], 'less', 'more', 'pager'] if commands.empty?
            commands.compact.uniq.find {|e| Util.command_exists?(e[/\w+/]) }
          end
      end

      # Pages with a ruby-only pager which either pages or quits.
      def default_pager(output, options={})
        pager = new(options[:width], options[:height])
        while pager.activated_by?(output, options[:inspect])
          puts pager.slice!(output, options[:inspect])
          return unless continue_paging?
        end
        puts output
        puts "=== Pager finished. ==="
      end

      #:stopdoc:
      def valid_pager_command?(cmd)
        cmd ? pager_command(cmd) : pager_command
      end

      private
      def basic_pager(output)
        pager = IO.popen(pager_command, "w")
        begin
          save_stdout = STDOUT.clone
          STDOUT.reopen(pager)
          STDOUT.puts output
        rescue Errno::EPIPE
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
      #:startdoc:
    end

    attr_reader :width, :height

    def initialize(width, height, options={})
      resize(width, height)
      @pager_command = options[:pager_command] if options[:pager_command]
    end

    # Pages given string using configured pager.
    def page(string, inspect_mode)
      if self.class.valid_pager_command?(@pager_command)
        self.class.command_pager(string, :pager_command=>@pager_command)
      else
        self.class.default_pager(string, :width=>@width, :height=>@height, :inspect=>inspect_mode)
      end
    end

    def slice!(output, inspect_mode=false) #:nodoc:
      effective_height = @height - 2 # takes into account pager prompt
      if inspect_mode
        sliced_output = String.slice(output, 0, @width * effective_height)
        output.replace String.slice(output, @width * effective_height, String.size(output))
        sliced_output
      else
        # could use output.scan(/[^\n]*\n?/) instead of split
        sliced_output = output.split("\n").slice(0, effective_height).join("\n")
        output.replace output.split("\n").slice(effective_height..-1).join("\n")
        sliced_output
      end
    end

    # Determines if string should be paged based on configured width and height.
    def activated_by?(string_to_page, inspect_mode=false)
      inspect_mode ? (String.size(string_to_page) > @height * @width) : (string_to_page.count("\n") > @height)
    end

    def resize(width, height) #:nodoc:
      @width, @height = View.determine_terminal_size(width, height)
    end
  end
end
