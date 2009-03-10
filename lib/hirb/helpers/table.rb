# Base Table class from which other table classes inherit.
# By default, a table is constrained to a default width but this can be adjusted
# via options as well as Hirb:Helpers::Table.max_width.
# Rows can be an array of arrays or an array of hashes.
#
# An array of arrays ie [[1,2], [2,3]], would render:
#   +---+---+
#   | 0 | 1 |
#   +---+---+
#   | 1 | 2 |
#   | 2 | 3 |
#   +---+---+
#
# By default, the fields/columns are the numerical indices of the array.
# 
# An array of hashes ie [{:age=>10, :weight=>100}, {:age=>80, :weight=>500}], would render:
#   +-----+--------+
#   | age | weight |
#   +-----+--------+
#   | 10  | 100    |
#   | 80  | 500    |
#   +-----+--------+
#
# By default, the fields/columns are the keys of the first hash.
#--
# derived from http://gist.github.com/72234
class Hirb::Helpers::Table
  DEFAULT_MAX_WIDTH = 150
  class << self
    attr_accessor :max_width
    
    # Main method which returns a formatted table.
    # ==== Options:
    # [:fields] An array which overrides the default fields and can be used to indicate field order.
    # [:headers] A hash of fields and their header names. Fields that aren't specified here default to their name.
    #            This option can also be an array but only for array rows.
    # [:field_lengths] A hash of fields and their maximum allowed lengths. If a field exceeds it's maximum
    #                  length than it's truncated and has a ... appended to it. Fields that aren't specified here have no maximum allowed
    #                  length.
    # [:max_width] The maximum allowed width of all fields put together. This option is enforced except when the field_lengths option is set.
    # Examples:
    #    Hirb::Helpers::Table.render [[1,2], [2,3]]
    #    Hirb::Helpers::Table.render [[1,2], [2,3]], :field_lengths=>{0=>10}
    #    Hirb::Helpers::Table.render [{:age=>10, :weight=>100}, {:age=>80, :weight=>500}]
    #    Hirb::Helpers::Table.render [{:age=>10, :weight=>100}, {:age=>80, :weight=>500}], :headers=>{:weight=>"Weight(lbs)"}
    def render(rows, options={})
      new(rows,options).render
    end
  end
  
  #:stopdoc:
  def initialize(rows, options={})
    @options = options
    @fields = options[:fields] || ((rows[0].is_a?(Hash)) ? rows[0].keys.sort {|a,b| a.to_s <=> b.to_s} : 
      rows[0].is_a?(Array) ? (0..rows[0].length - 1).to_a : [])
    @rows = setup_rows(rows)
    @headers = @fields.inject({}) {|h,e| h[e] = e.to_s; h}
    if options.has_key?(:headers)
      @headers = options[:headers].is_a?(Hash) ? @headers.merge(options[:headers]) : 
        (options[:headers].is_a?(Array) ? array_to_indices_hash(options[:headers]) : options[:headers])
    end
  end
  
  def setup_rows(rows)
    rows ||= []
    rows = [rows] unless rows.is_a?(Array)
    if rows[0].is_a?(Array)
      rows = rows.inject([]) {|new_rows, row|
        new_rows << array_to_indices_hash(row)
      }
    end
    validate_values(rows)
    rows
  end
  
  def render
    body = []
    unless @rows.length == 0
      setup_field_lengths
      body += @headers ? render_header : [render_border]
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
  
  # Simple algorithm which given a max width, allows smaller fields to be displayed while
  # restricting longer fields at a new_long_field_length.
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
    field_lengths = @headers ? @headers.inject({}) {|h,(k,v)| h[k] = v.length; h} : {}
    @rows.each do |row|
      @fields.each do |field|
        len = row[field].length
        field_lengths[field] = len if len > field_lengths[field].to_i
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
  
  # Converts an array to a hash mapping a numerical index to its array value.
  def array_to_indices_hash(array)
    array.inject({}) {|hash,e|  hash[hash.size] = e; hash }
  end
  #:startdoc:
end
