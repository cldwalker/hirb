# modified from http://gist.github.com/72234

class Hirb::Helpers::Table
  class << self
    attr_accessor :max_width
    # item_hashes an array of hashes
    def render(item_hashes, options={})
      fields = options[:fields] || item_hashes[0].keys
      return "0 rows in set" if item_hashes.size == 0
      stringify_values(item_hashes)

      if options[:field_lengths]
        field_lengths = options[:field_lengths]
      else
        field_lengths = calculate_field_lengths(item_hashes, fields)
        local_width = options[:max_width] || Hirb::Helpers::Table.max_width || 150
        ensure_safe_field_lengths(field_lengths, local_width)
      end

      border = '+-' + fields.map {|f| '-' * field_lengths[f] }.join('-+-') + '-+'
      title_row = '| ' + fields.map {|f| sprintf("%-#{field_lengths[f]}s", f.to_s) }.join(' | ') + ' |'
      body = [border, title_row, border]

      item_hashes.each do |item|
        row = '| ' + fields.map {|f| sprintf("%-#{field_lengths[f]}s", item[f].slice(0, field_lengths[f])) }.join(' | ') + ' |'
        body << row
      end

      body << border
      body << "#{item_hashes.length} rows in set"
      body.join("\n")
    end

    def ensure_safe_field_lengths(field_lengths, max_total_length)
      fields = field_lengths.keys
      total_length = field_lengths.values.inject {|t,n| t += n}
      if total_length > max_total_length
        average_field_length = total_length / fields.size.to_f
        long_lengths, short_lengths = field_lengths.values.partition {|e| e > average_field_length}
        new_long_field_length = (max_total_length - short_lengths.inject {|t,n| t += n}) / long_lengths.size
        field_lengths.each {|f,length|
          field_lengths[f] = new_long_field_length if length > new_long_field_length
        }
      end
    end

    def calculate_field_lengths(hash_array, fields=nil)
      return {} if hash_array.empty?
      fields ||= hash_array[0].keys
      # find max length for each field; start with the field names themselves
      field_lengths = Hash[*fields.map {|f| [f, f.to_s.length]}.flatten]
      hash_array.each do |item|
        fields.each do |field|
          len = item[field].length
          field_lengths[field] = len if len > field_lengths[field]
        end
      end
      field_lengths
    end
  
    def stringify_values(hash_array)
      hash_array.each {|e|
        e.each {|k,v| e[k] = v.to_s }
      }
    end
  end
end