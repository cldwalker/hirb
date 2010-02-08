class Hirb::Helpers::Table
  # Resizes a table's fields to the table's max width.
  class Resizer
    # Modifies field_lengths to fit within width. Also enforces a table's max_fields.
    def self.resize!(table)
      obj = new(table)
      obj.resize
      obj.field_lengths
    end

    #:stopdoc:
    attr_reader :field_lengths
    def initialize(table)
      @table, @width, @field_size = table, table.actual_width, table.fields.size
      @field_lengths = table.field_lengths
      @original_field_lengths = @field_lengths.dup
    end

    def resize
      adjust_long_fields || default_restrict_field_lengths
      @table.enforce_field_constraints
      add_extra_width
    end

    # Simple algorithm which allows smaller fields to be displayed while
    # restricting longer fields to an average_long_field
    def adjust_long_fields
      while (total_length = sum(@field_lengths.values)) > @width
        average_field = total_length / @field_size.to_f
        long_lengths = @field_lengths.values.select {|e| e > average_field }
        return false if long_lengths.empty?

        # adjusts average long field by ratio with @width
        average_long_field = sum(long_lengths)/long_lengths.size * @width/total_length
        @field_lengths.each {|f,length|
          @field_lengths[f] = average_long_field if length > average_long_field
        }
      end
      true
    end

    # Produces a field_lengths which meets the @width requirement
    def default_restrict_field_lengths
      original_total_length = sum @original_field_lengths.values
      # set fields by their relative weight to original length
      new_lengths = @original_field_lengths.inject({}) {|t,(k,v)|
        t[k] = (v / original_total_length.to_f * @width).to_i; t  }

      # set all fields the same if relative doesn't work
      unless new_lengths.values.all? {|e| e > MIN_FIELD_LENGTH} && (sum(new_lengths.values) <= @width)
        new_lengths = @field_lengths.inject({}) {|t,(k,v)| t[k] = @width / @field_size; t }
      end
      @field_lengths.each {|k,v| @field_lengths[k] = new_lengths[k] }
    end

    def add_extra_width
      added_width = 0
      extra_width = @width - sum(@field_lengths.values)
      unmaxed_fields = @field_lengths.keys.select {|f| !remaining_width(f).zero? }
      # order can affect which one gets the remainder so let's keep it consistent
      unmaxed_fields = unmaxed_fields.sort_by {|e| e.to_s}

      unmaxed_fields.each_with_index do |f, i|
        extra_per_field = (extra_width - added_width) / (unmaxed_fields.size - i)
        add_to_field = remaining_width(f) < extra_per_field ? remaining_width(f) : extra_per_field
        added_width += add_to_field
        @field_lengths[f] += add_to_field
      end
    end

    def remaining_width(field)
      (@remaining_width ||= {})[field] ||= begin
        (@table.max_fields[field] || @original_field_lengths[field]) - @field_lengths[field]
      end
    end

    def sum(arr)
      arr.inject {|t,e| t += e }
    end
    #:startdoc:
  end
end