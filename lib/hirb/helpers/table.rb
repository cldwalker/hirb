# modified from http://gist.github.com/72234

class Hirb::Helpers::Table
  class << self
    attr_accessor :max_width
    
    def render(*args)
      new(*args).render
    end
  end
  
  # item_hashes an array of hashes
  def initialize(rows, options={})
    @options = options
    @rows = prepare_rows(rows)
    @fields = options[:fields] || ((@rows[0].is_a?(Hash)) ? @rows[0].keys.sort {|a,b| a.to_s <=> b.to_s} : [])
  end
  
  def prepare_rows(rows)
    rows ||= []
    rows = [rows] unless rows.is_a?(Array)
    stringify_values(rows)
    rows
  end
  
  def render
    body = []
    unless @rows.length == 0
      @field_lengths = get_field_lengths
      body += render_header
      body += render_rows
      body << render_border
    end
    body << render_table_description
    body.join("\n")
  end
  
  def render_header
    title_row = '| ' + @fields.map {|f| sprintf("%-#{@field_lengths[f]}s", f.to_s) }.join(' | ') + ' |'
    [render_border, title_row, render_border]
  end
  
  def render_border
    '+-' + @fields.map {|f| '-' * @field_lengths[f] }.join('-+-') + '-+'
  end
  
  def render_rows
    @rows.map do |item|
      row = '| ' + @fields.map {|f|
        text = item[f].length > @field_lengths[f] ? item[f].slice(0,@field_lengths[f] - 3) + '...' : item[f]
        sprintf("%-#{@field_lengths[f]}s", text)
      }.join(' | ') + ' |'
    end
  end
  
  def render_table_description
    (@rows.length == 0) ? "0 rows in set" :
      "#{@rows.length} #{@rows.length == 1 ? 'row' : 'rows'} in set"
  end
  
  def get_field_lengths
    @options[:field_lengths] || begin
      field_lengths = calculate_field_lengths(@rows, @fields)
      local_width = @options[:max_width] || Hirb::Helpers::Table.max_width || 150
      ensure_safe_field_lengths(field_lengths, local_width)
      field_lengths
    end
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