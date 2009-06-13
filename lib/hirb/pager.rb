module Hirb
  class Pager
    class<<self
      def shell_pager(obj, options={})
        @pager = IO.popen(pager_binary, "w")
        begin
          save_stdout = STDOUT.clone
          STDOUT.reopen(@pager)    
          puts obj
        ensure
         STDOUT.reopen(save_stdout)
         save_stdout.close
         @pager.close
        end
      end

      def has_valid_pager?
        !! pager_binary
      end

      def pager_binary
        @pager_binary ||= [ ENV['PAGER'], 'pager', 'less', 'more'].compact.uniq.find {|e|
          ENV['PATH'].split(File::PATH_SEPARATOR).any? {|d| File.exists? File.join(d, e) }
        }
      end

      # TODO
      def default_pager(output, width_detection=false, options={})
        lines = output.scan(/[^\n]*\n?/)
        while lines.size > height
          puts lines.slice!(0...height).join
          return unless continue_paging?
        end
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

    def page(string)
      self.class.shell_pager(string)
    end

    def activated_by?(string_to_page, width_detection=false)
      if width_detection
        string_to_page.size > @height * @width
      else
        string_to_page.count("\n") > @height
      end
    end

    # these environment variables should work for *nix, others should use highline's Highline::SystemExtensions.terminal_size
    def resize(width, height)
      @width = width || ENV['COLUMNS'] =~ /^\d+$/ ? ENV['COLUMNS'].to_i : 150
      @height = height || ENV['LINES'] =~ /^\d+$/ ? ENV['LINES'].to_i : 50
    end
  end
end