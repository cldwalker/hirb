class Hirb::Helpers::Table
  # Resizes a table's fields given a desired width
  class Resizer
    def self.resize(field_lengths, width, fields)
      new(fields).resize(field_lengths, width)
    end

    def initialize(fields)
      @fields = fields
    end

    def resize(field_lengths, max_width)
      max_width -= @fields.size * BORDER_LENGTH + 1
      original_field_lengths = field_lengths.dup
      @min_field_length = BORDER_LENGTH
      adjust_long_fields(field_lengths, max_width) ||
        default_restrict_field_lengths(field_lengths, original_field_lengths, max_width)
    end

    def sum(arr)
      arr.inject {|t,e| t += e }
    end

    # Simple algorithm which given a max width, allows smaller fields to be displayed while
    # restricting longer fields at an average_long_field_length.
    def adjust_long_fields(field_lengths, max_width)
      total_length = sum field_lengths.values
      while total_length > max_width
        raise TooManyFieldsForWidthError if @fields.size > max_width.to_f / @min_field_length
        average_field_length = total_length / @fields.size.to_f
        long_lengths = field_lengths.values.select {|e| e > average_field_length}
        return false if long_lengths.empty?

        total_long_field_length = sum(long_lengths) * max_width/total_length
        average_long_field_length = total_long_field_length / long_lengths.size
        field_lengths.each {|f,length|
          field_lengths[f] = average_long_field_length if length > average_long_field_length
        }
        total_length = sum field_lengths.values
      end
      true
    end

    # Produces a field_lengths which meets the max_width requirement
    def default_restrict_field_lengths(field_lengths, original_field_lengths, max_width)
      original_total_length = sum original_field_lengths.values
      relative_lengths = original_field_lengths.values.map {|v| (v / original_total_length.to_f * max_width).to_i  }
      # set fields by their relative weight to original length
      if relative_lengths.all? {|e| e > @min_field_length} && (sum(relative_lengths) <= max_width)
        original_field_lengths.each {|k,v| field_lengths[k] = (v / original_total_length.to_f * max_width).to_i }
      else
        # set all fields the same if nothing else works
        field_lengths.each {|k,v| field_lengths[k] = max_width / @fields.size}
      end
    end
  end
end