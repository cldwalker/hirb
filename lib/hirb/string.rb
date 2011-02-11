require 'unicode/display_width'

module Hirb
  # Provides string helpers to deal with UTF-8 and ruby 1.8.x
  module String
    extend self
    # :stopdoc:
    if RUBY_VERSION < '1.9'
      def display_width(string)
        string.display_width
      end

      def ljust(string, desired_length)
        leftover = desired_length - display_width(string)
        leftover > 0 ? string + " " * leftover : string
      end

      def rjust(string, desired_length)
        leftover = desired_length - display_width(string)
        leftover > 0 ? " " * leftover + string : string
      end

      # def split_at_display_width(string, start, width)
        # string.scan(/./).slice(start, finish).join('')
      # end

      def slice(string, start, finish)
        string.scan(/./).slice(start, finish).join('')
      end
    else
      def size(string)
        string.length
      end

      def ljust(string, desired_length)
        string.ljust(desired_length)
      end

      def rjust(string, desired_length)
        string.rjust(desired_length)
      end

      def slice(*args)
        string = args.shift
        string.slice(*args)
      end
    end
    #:startdoc:
  end
end
