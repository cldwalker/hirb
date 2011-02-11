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

      def truncate(string, width)
        truncated, remaining = split_at_display_width(string, width)
        truncated
      end

      # Split the original string into 2 string.
      # The first string has most possible length but can't be longer than width
      def split_at_display_width(string, width)
        chars = string.chars.to_a

        current_length = 0
        split_at = nil
        chars.each_with_index do |c, i|
          char_width = display_width(c)
          if current_length + char_width > width
            split_at = i
            break
          end
          current_length += char_width
        end

        split_at ||= chars.count
        head = chars[0, split_at].to_s
        tail = chars[split_at, chars.count].to_s
        [head, tail]
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
