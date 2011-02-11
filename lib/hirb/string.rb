require 'unicode/display_width'

module Hirb
  # Provides string helpers to deal with UTF-8 and ruby 1.8.x
  module String

    extend self

    # :stopdoc:

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
      split_at_display_width(string, width).first
    end

    # Split the original string into 2 string.
    # The first string has most possible length but can't be longer than width
    def split_at_display_width(string, width)
      chars = string.chars.to_a

      current_length = 0
      split_index = 0
      chars.each_with_index do |c, i|
        char_width = display_width(c)
        break if current_length + char_width > width
        split_index = i+1
        current_length += char_width
      end

      split_index ||= chars.count
      head = chars[0, split_index].join
      tail = chars[split_index, chars.count].join
      [head, tail]
    end

    #:startdoc:
    #
  end
end
