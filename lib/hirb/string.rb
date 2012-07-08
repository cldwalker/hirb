module Hirb
  # Provides string helpers to deal with UTF-8 and ruby 1.8.x
  module String
    COLORIZED_REGEX = /\e\[\d+m/

    extend self
    # :stopdoc:
    if RUBY_VERSION < '1.9'
      def size(string)
        string.gsub(COLORIZED_REGEX, '').scan(/./).length
      end

      def ljust(string, desired_length)
        leftover = desired_length - size(string)
        leftover > 0 ? string + " " * leftover : string
      end

      def rjust(string, desired_length)
        leftover = desired_length - size(string)
        leftover > 0 ? " " * leftover + string : string
      end

      def slice(string, start, finish)
        if string =~ COLORIZED_REGEX
          slice_colorized_string(string, start, finish)
        else
          string.scan(/./).slice(start, finish).join('')
        end
      end
    else
      def size(string)
        string.gsub(COLORIZED_REGEX, '').length
      end

      def ljust(string, desired_length)
        leftover = desired_length - size(string)

        leftover > 0 ? string + " " * leftover : string
      end

      def rjust(string, desired_length)
        leftover = desired_length - size(string)

        leftover > 0 ? " " * leftover + string : string
      end

      def slice(*args)
        string = args.shift

        # if string contains colorization code
        if string =~ COLORIZED_REGEX
          slice_start, slice_end = args

          slice_colorized_string(string, slice_start, slice_end)
        else
          string.slice(*args)
        end

      end

    end

    def slice_colorized_string(string, slice_start, slice_end)
      # store the codes and their position in the original string
      codes_with_position = []
      string.scan(COLORIZED_REGEX) do |c|
        codes_with_position << [c, Regexp.last_match.offset(0).first]
      end

      # sort the codes according to where they will fall in the slice
      codes_before_slice = []
      codes_in_slice     = []
      codes_after_slice  = []
      codes_with_position.size.times do
        code = codes_with_position.shift
        # shift remaining codes position by that of the popped code
        codes_with_position.map! { |c| c[1] -= code.first.size; c }
        if code.last <= slice_start
          codes_before_slice << code
        elsif code.last > slice_start && code.last < slice_end
          codes_in_slice << code
        else
          codes_after_slice << code
        end
      end

      # slice the string without the codes
      slice = string.gsub(COLORIZED_REGEX, '').slice(slice_start, slice_end)

      # insert codes back into the slice
      codes_in_slice.each do |code|
        slice.insert(code.last, code.first)
        # adjust positions of remaining codes
        codes_in_slice.map! { |c| c[1] += code.first.size; c }
      end

      # prepend codes that came before slice
      codes_before_slice.each { |code| slice.insert(0, code.first)}

      # append codes that came after slice
      codes_after_slice.each { |code| slice << code.first }

      # return the color coded slice
      slice
    end
    #:startdoc:
  end
end