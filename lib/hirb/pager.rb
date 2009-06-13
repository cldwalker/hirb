module Hirb
  class Pager
    class<<self
      def shell_pager(obj, options={})
        pager = IO.popen(pager_binary, "w")
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

      def has_valid_pager?
        !! pager_binary
      end

      def pager_binary
        @pager_binary ||= [ ENV['PAGER'], 'less', 'more', 'pager'].compact.uniq.find {|e|
          ENV['PATH'].split(File::PATH_SEPARATOR).any? {|d| File.exists? File.join(d, e) }
        }
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
      def continue_paging?
        puts "=== Press enter/return to continue or q to quit: ==="
        !gets.chomp[/q/i]
      end
      
    end

    attr_reader :width, :height

    def initialize(width, height)
      resize(width, height)
    end

    def page(string, inspect_mode)
      self.class.has_valid_pager? ? self.class.shell_pager(string) :
        default_pager(string, :width=>@width, :height=>@height, :inspect=>inspect_mode)
    end

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
      if inspect_mode
        string_to_page.size > @height * @width
      else
        string_to_page.count("\n") > @height
      end
    end

    # these environment variables should work for *nix, others should use highline's Highline::SystemExtensions.terminal_size
    def resize(width, height)
      @width = width || (ENV['COLUMNS'] =~ /^\d+$/ ? ENV['COLUMNS'].to_i : 150)
      @height = height || (ENV['LINES'] =~ /^\d+$/ ? ENV['LINES'].to_i : 50)
    end
  end
end
