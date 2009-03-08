# modified from http://gist.github.com/72234

class Hirb::Helpers::Table
  DEFAULT_MAX_WIDTH = 150
  class << self
    attr_accessor :max_width
    
    def render(*args)
      new(*args).render
    end
  end
  
  # rows can be an array of hashes
  def initialize(rows, options={})
    @options = options
    @fields = options[:fields] || ((rows[0].is_a?(Hash)) ? rows[0].keys.sort {|a,b| a.to_s <=> b.to_s} : [])
    @rows = setup_rows(rows)
    @headers = @fields.inject({}) {|h,e| h[e] = e.to_s; h}
    @headers.merge!(options[:headers]) if options[:headers]
  end
  
  def setup_rows(rows)
    rows ||= []
    rows = [rows] unless rows.is_a?(Array)
    validate_values(rows)
    rows
  end
  
  def render
    body = []
    unless @rows.length == 0
      setup_field_lengths
      body += render_header
      body += render_rows
      body << render_border
    end
    body << render_table_description
    body.join("\n")
  end
  
  def render_header
    title_row = '| ' + @fields.map {|f|
      format_cell(@headers[f], @field_lengths[f])
    }.join(' | ') + ' |'
    [render_border, title_row, render_border]
  end
  
  def render_border
    '+-' + @fields.map {|f| '-' * @field_lengths[f] }.join('-+-') + '-+'
  end
  
  def format_cell(value, cell_width)
    text = value.length > cell_width ? 
      (
      (cell_width < 3) ? value.slice(0,cell_width) : value.slice(0, cell_width - 3) + '...'
      ) : value
    sprintf("%-#{cell_width}s", text)
  end
  
  def render_rows
    @rows.map do |row|
      row = '| ' + @fields.map {|f|
        format_cell(row[f], @field_lengths[f])
      }.join(' | ') + ' |'
    end
  end
  
  def render_table_description
    (@rows.length == 0) ? "0 rows in set" :
      "#{@rows.length} #{@rows.length == 1 ? 'row' : 'rows'} in set"
  end
  
  def setup_field_lengths
    @field_lengths = default_field_lengths
    if @options[:field_lengths]
      @field_lengths.merge!(@options[:field_lengths])
    else
      max_width = @options[:max_width] || Hirb::Helpers::Table.max_width || DEFAULT_MAX_WIDTH
      restrict_field_lengths(@field_lengths, max_width)
    end
  end
  
  def restrict_field_lengths(field_lengths, max_width)
    total_length = field_lengths.values.inject {|t,n| t += n}
    if total_length > max_width
      average_field_length = total_length / @fields.size.to_f
      long_lengths, short_lengths = field_lengths.values.partition {|e| e > average_field_length}
      new_long_field_length = (max_width - short_lengths.inject {|t,n| t += n}) / long_lengths.size
      field_lengths.each {|f,length|
        field_lengths[f] = new_long_field_length if length > new_long_field_length
      }
    end
  end

  # find max length for each field; start with the headers
  def default_field_lengths
    field_lengths = @headers.inject({}) {|h,(k,v)| h[k] = v.length; h}
    @rows.each do |row|
      @fields.each do |field|
        len = row[field].length
        field_lengths[field] = len if len > field_lengths[field]
      end
    end
    field_lengths
  end

  def validate_values(rows)
    rows.each {|row|
      @fields.each {|f|
        row[f] = row[f].to_s || ''
      }
    }
  end
end