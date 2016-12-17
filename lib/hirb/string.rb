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
      markers = []
      string.scan(COLORIZED_REGEX) do |code|
        marker = { :code     => code,
                   :position => Regexp.last_match.offset(0).first
                 }
        markers << marker
      end

      markers_before_slice = []
      markers_in_slice     = []
      markers_after_slice  = []
      # interate over elements in code_markers
      # will be mutating array so cannot use .each
      markers.size.times do
        marker = markers.shift
        # shift remaining markers position by that of the popped code
        markers.map! { |c| c[:position] -= marker[:code].size; c }
        if marker[:position] <= slice_start
          markers_before_slice << marker
        elsif marker[:position] > slice_start && marker[:position] < slice_end
          markers_in_slice << marker
        else
          markers_after_slice << marker
        end
      end

      # slice the string without the codes
      slice = string.gsub(COLORIZED_REGEX, '').slice(slice_start, slice_end)

      # insert codes back into the slice
      markers_in_slice.each do |marker|
        slice.insert(marker[:position], marker[:code])
        markers_in_slice.map! { |c| c[:position] += marker[:code].size; c }
      end

      markers_before_slice.each { |marker| slice.insert(0, marker[:code])}
      markers_after_slice.each { |marker| slice << marker[:code] }

      slice
    end
    #:startdoc:
  end
end