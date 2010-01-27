class Hirb::Helpers::Table
  # Resizes a table's fields to the width if it exceeds that width
  class Resizer
    # Modifies field_lengths to fit within width
    def self.resize!(field_lengths, width)
      obj = new(field_lengths, width)
      obj.resize
      obj.field_lengths
    end

    #:stopdoc:
    attr_reader :field_lengths
    def initialize(field_lengths, width)
      @width = width
      @field_lengths = field_lengths
      @field_size = field_lengths.size
      @width -= @field_size * BORDER_LENGTH + 1
      @min_field_length = BORDER_LENGTH
      @original_field_lengths = field_lengths.dup
    end

    def resize
      adjust_long_fields || default_restrict_field_lengths
    end

    # Simple algorithm which given a max width, allows smaller fields to be displayed while
    # restricting longer fields at an average_long_field_length.
    def adjust_long_fields
      total_length = sum @field_lengths.values
      while total_length > @width
        raise TooManyFieldsForWidthError if @field_size > @width.to_f / @min_field_length
        average_field_length = total_length / @field_size.to_f
        long_lengths = @field_lengths.values.select {|e| e > average_field_length}
        return false if long_lengths.empty?

        total_long_field_length = sum(long_lengths) * @width/total_length
        average_long_field_length = total_long_field_length / long_lengths.size
        @field_lengths.each {|f,length|
          @field_lengths[f] = average_long_field_length if length > average_long_field_length
        }
        total_length = sum @field_lengths.values
      end
      true
    end

    # Produces a field_lengths which meets the @width requirement
    def default_restrict_field_lengths
      original_total_length = sum @original_field_lengths.values
      relative_lengths = @original_field_lengths.values.map {|v| (v / original_total_length.to_f * @width).to_i  }
      # set fields by their relative weight to original length
      if relative_lengths.all? {|e| e > @min_field_length} && (sum(relative_lengths) <= @width)
        @original_field_lengths.each {|k,v| @field_lengths[k] = (v / original_total_length.to_f * @width).to_i }
      else
        # set all fields the same if nothing else works
        @field_lengths.each {|k,v| @field_lengths[k] = @width / @field_size}
      end
    end

    def sum(arr)
      arr.inject {|t,e| t += e }
    end
    #:startdoc:
  end
end