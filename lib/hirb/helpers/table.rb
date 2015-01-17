# -*- encoding : utf-8 -*-
require 'hirb/helpers/table/filters'
require 'hirb/helpers/table/resizer'

module Hirb
# Base Table class from which other table classes inherit.
# By default, a table is constrained to a default width but this can be adjusted
# via the max_width option or Hirb::View.width.
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
#
# === Custom Callbacks
# Callback methods can be defined to add your own options that modify rows right before they are rendered.
# Here's an example that allows for searching with a :query option:
#   module Query
#     # Searches fields given a query hash
#     def query_callback(rows, options)
#       return rows unless options[:query]
#       options[:query].map {|field,query|
#         rows.select {|e| e[field].to_s =~ /#{query}/i }
#       }.flatten.uniq
#     end
#   end
#   Hirb::Helpers::Table.send :include, Query
#
#   >> puts Hirb::Helpers::Table.render [{:name=>'batman'}, {:name=>'robin'}], :query=>{:name=>'rob'}
#   +-------+
#   | name  |
#   +-------+
#   | robin |
#   +-------+
#   1 row in set
#
# Callback methods:
# * must be defined in Helpers::Table and end in '_callback'.
# * should expect rows and a hash of render options. Rows will be an array of hashes.
# * are expected to return an array of hashes.
# * are invoked in alphabetical order.
# For a thorough example, see {Boson::Pipe}[http://github.com/cldwalker/boson/blob/master/lib/boson/pipe.rb].
#--
# derived from http://gist.github.com/72234
class Helpers::Table
  BORDER_LENGTH = 3 # " | " and "-+-" are the borders
  MIN_FIELD_LENGTH = 3
  class TooManyFieldsForWidthError < StandardError; end

  CHARS = {
    :top => {:left => '+', :center => '+', :right => '+', :horizontal => '-',
      :vertical => {:outside => '|', :inside => '|'} },
    :middle => {:left => '+', :center => '+', :right => '+', :horizontal => '-'},
    :bottom => {:left => '+', :center => '+', :right => '+', :horizontal => '-',
      :vertical => {:outside => '|', :inside => '|'} }
  }

  class << self

    # Main method which returns a formatted table.
    # ==== Options:
    # [*:fields*] An array which overrides the default fields and can be used to indicate field order.
    # [*:headers*] A hash of fields and their header names. Fields that aren't specified here default to their name.
    #              When set to false, headers are hidden. Can also be an array but only for array rows.
    # [*:max_fields*] A hash of fields and their maximum allowed lengths. Maximum length can also be a percentage of the total width
    #                 (decimal less than one). When a field exceeds it's maximum then it's
    #                 truncated and has a ... appended to it. Fields that aren't specified have no maximum.
    # [*:max_width*] The maximum allowed width of all fields put together including field borders. Only valid when :resize is true.
    #                Default is Hirb::View.width.
    # [*:resize*] Resizes table to display all columns in allowed :max_width. Default is true. Setting this false will display the full
    #             length of each field.
    # [*:number*] When set to true, numbers rows by adding a :hirb_number column as the first column. Default is false.
    # [*:change_fields*] A hash to change old field names to new field names. This can also be an array of new names but only for array rows.
    #                    This is useful when wanting to change auto-generated keys to more user-friendly names i.e. for array rows.
    # [*:grep_fields*] A regexp that selects which fields to display. By default this is not set and applied.
    # [*:filters*] A hash of fields and their filters, applied to every row in a field. A filter can be a proc, an instance method
    #              applied to the field value or a Filters method. Also see the filter_classes attribute below.
    # [*:header_filter*] A filter, like one in :filters, that is applied to all headers after the :headers option.
    # [*:filter_any*] When set to true, any cell defaults to being filtered by its class in :filter_classes.
    #                 Default Hirb::Helpers::Table.filter_any().
    # [*:filter_classes*] Hash which maps classes to filters. Default is Hirb::Helpers::Table.filter_classes().
    # [*:all_fields*] When set to true, renders fields in all rows. Valid only in rows that are hashes. Default is false.
    # [*:description*] When set to true, renders row count description at bottom. Default is true.
    # [*:escape_special_chars*] When set to true, escapes special characters \n,\t,\r so they don't disrupt tables. Default is false for
    #                           vertical tables and true for anything else.
    # [*:vertical*] When set to true, renders a vertical table using Hirb::Helpers::VerticalTable. Default is false.
    # [*:unicode*] When set to true, renders a unicode table using Hirb::Helpers::UnicodeTable. Default is false.
    # [*:tab*] When set to true, renders a tab-delimited table using Hirb::Helpers::TabTable. Default is false.
    # [*:style*] Choose style of table: :simple, :vertical, :unicode, :tab or :markdown. :simple
    #            just uses the default render. Other values map to a capitalized namespace in format
    #            Hirb::Helpers::OptionValTable.
    #
    # Examples:
    #    Hirb::Helpers::Table.render [[1,2], [2,3]]
    #    Hirb::Helpers::Table.render [[1,2], [2,3]], :max_fields=>{0=>10}, :header_filter=>:capitalize
    #    Hirb::Helpers::Table.render [['a',1], ['b',2]], :change_fields=>%w{letters numbers}, :max_fields=>{'numbers'=>0.4}
    #    Hirb::Helpers::Table.render [{:age=>10, :weight=>100}, {:age=>80, :weight=>500}]
    #    Hirb::Helpers::Table.render [{:age=>10, :weight=>100}, {:age=>80, :weight=>500}], :headers=>{:weight=>"Weight(lbs)"}
    #    Hirb::Helpers::Table.render [{:age=>10, :weight=>100}, {:age=>80, :weight=>500}], :filters=>{:age=>[:to_f]}
    #    Hirb::Helpers::Table.render [{:age=>10, :weight=>100}, {:age=>80, :weight=>500}], :style=> :simple}
    def render(rows, options={})
      choose_style(rows, options)
    rescue TooManyFieldsForWidthError
      $stderr.puts "", "** Hirb Warning: Too many fields for the current width. Configure your width " +
        "and/or fields to avoid this error. Defaulting to a vertical table. **"
      Helpers::VerticalTable.render(rows, options)
    end

    def choose_style(rows, options)
      case options[:style]
      when :vertical
        Helpers::VerticalTable.render(rows, options)
      when :unicode
        Helpers::UnicodeTable.render(rows, options)
      when :tab
        Helpers::TabTable.render(rows, options)
      when :markdown
        Helpers::MarkdownTable.render(rows, options)
      when :simple
        new(rows, options).render
      else
        options[:vertical] ? Helpers::VerticalTable.render(rows, options) :
          options[:unicode]  ? Helpers::UnicodeTable.render(rows, options) :
          options[:tab]      ? Helpers::TabTable.render(rows, options) :
          options[:markdown] ? Helpers::MarkdownTable.render(rows, options) :
          new(rows, options).render
      end
    end
    private :choose_style

    # A hash which maps a cell value's class to a filter. This serves to set a default filter per field if all of its
    # values are a class in this hash. By default, Array values are comma joined and Hashes are inspected.
    # See the :filter_any option to apply this filter per value.
    attr_accessor :filter_classes
    # Boolean which sets the default for :filter_any option.
    attr_accessor :filter_any
    # Holds last table object created
    attr_accessor :last_table
  end
  self.filter_classes = { Array=>:comma_join, Hash=>:inspect }


  def chars
    self.class.const_get(:CHARS)
  end

  #:stopdoc:
  attr_accessor :width, :max_fields, :field_lengths, :fields
  def initialize(rows, options={})
    raise ArgumentError, "Table must be an array of hashes or array of arrays" unless rows.is_a?(Array) &&
      (rows[0].is_a?(Hash) or rows[0].is_a?(Array) or rows.empty?)
    @options = {:description=>true, :filters=>{}, :change_fields=>{}, :escape_special_chars=>true,
      :filter_any=>Helpers::Table.filter_any, :resize=>true}.merge(options)
    @fields = set_fields(rows)
    @fields = @fields.select {|e| e.to_s[@options[:grep_fields]] } if @options[:grep_fields]
    @rows = set_rows(rows)
    @headers = set_headers
    if @options[:number]
      @headers[:hirb_number] ||= "number"
      @fields.unshift :hirb_number
    end
    Helpers::Table.last_table = self
  end

  def set_fields(rows)
    @options[:change_fields] = array_to_indices_hash(@options[:change_fields]) if @options[:change_fields].is_a?(Array)
    return @options[:fields].dup if @options[:fields]

    fields = if rows[0].is_a?(Hash)
      keys = @options[:all_fields] ? rows.map {|e| e.keys}.flatten.uniq : rows[0].keys
      keys.sort {|a,b| a.to_s <=> b.to_s}
    else
      rows[0].is_a?(Array) ? (0..rows[0].length - 1).to_a : []
    end

    @options[:change_fields].each do |oldf, newf|
      (index = fields.index(oldf)) && fields[index] = newf
    end
    fields
  end

  def set_rows(rows)
    rows = Array(rows)
    if rows[0].is_a?(Array)
      rows = rows.inject([]) {|new_rows, row|
        new_rows << array_to_indices_hash(row)
      }
    end
    @options[:change_fields].each do |oldf, newf|
      rows.each {|e| e[newf] = e.delete(oldf) if e.key?(oldf) }
    end
    rows = filter_values(rows)
    rows.each_with_index {|e,i| e[:hirb_number] = (i + 1).to_s} if @options[:number]
    deleted_callbacks = Array(@options[:delete_callbacks]).map {|e| "#{e}_callback" }
    (methods.grep(/_callback$/).map {|e| e.to_s} - deleted_callbacks).sort.each do |meth|
      rows = send(meth, rows, @options.dup)
    end
    validate_values(rows)
    rows
  end

  def set_headers
    headers = @fields.inject({}) {|h,e| h[e] = e.to_s; h}
    if @options.has_key?(:headers)
      headers = @options[:headers].is_a?(Hash) ? headers.merge(@options[:headers]) :
        (@options[:headers].is_a?(Array) ? array_to_indices_hash(@options[:headers]) : @options[:headers])
    end
    if @options[:header_filter]
      headers.each {|k,v|
        headers[k] = call_filter(@options[:header_filter], v)
      }
    end
    headers
  end

  def render
    body = []
    unless @rows.length == 0
      setup_field_lengths
      body += render_header
      body += render_rows
      body += render_footer
    end
    body << render_table_description if @options[:description]
    body.join("\n")
  end

  def render_header
    @headers ? render_table_header : [render_border(:top)]
  end

  def render_footer
    [render_border(:bottom)]
  end

  def render_table_header
    title_row = chars[:top][:vertical][:outside] + ' ' +
      format_values(@headers).join(' ' + chars[:top][:vertical][:inside] +' ') +
      ' ' + chars[:top][:vertical][:outside]
    [render_border(:top), title_row, render_border(:middle)]
  end

  def render_border(which)
    chars[which][:left] + chars[which][:horizontal] +
      @fields.map {|f| chars[which][:horizontal] * @field_lengths[f] }.
      join(chars[which][:horizontal] + chars[which][:center] + chars[which][:horizontal]) +
      chars[which][:horizontal] + chars[which][:right]
  end

  def format_values(values)
    @fields.map {|field| format_cell(values[field], @field_lengths[field]) }
  end

  def format_cell(value, cell_width)
    text = String.size(value) > cell_width ?
      (
      (cell_width < 5) ? String.slice(value, 0, cell_width) : String.slice(value, 0, cell_width - 3) + '...'
      ) : value
    String.ljust(text, cell_width)
  end

  def render_rows
    @rows.map do |row|
      chars[:bottom][:vertical][:outside] + ' ' +
        format_values(row).join(' ' + chars[:bottom][:vertical][:inside] + ' ') +
        ' ' + chars[:bottom][:vertical][:outside]
    end
  end

  def render_table_description
    (@rows.length == 0) ? "0 rows in set" :
      "#{@rows.length} #{@rows.length == 1 ? 'row' : 'rows'} in set"
  end

  def setup_field_lengths
    @field_lengths = default_field_lengths
    if @options[:resize]
      raise TooManyFieldsForWidthError if @fields.size > self.actual_width.to_f / MIN_FIELD_LENGTH
      Resizer.resize!(self)
    else
      enforce_field_constraints
    end
  end

  def enforce_field_constraints
    max_fields.each {|k,max| @field_lengths[k] = max if @field_lengths[k].to_i > max }
  end

  undef :max_fields
  def max_fields
    @max_fields ||= (@options[:max_fields] ||= {}).each {|k,v|
      @options[:max_fields][k] = (actual_width * v.to_f.abs).floor if v.to_f.abs < 1
    }
  end

  def actual_width
    @actual_width ||= self.width - (@fields.size * BORDER_LENGTH + 1)
  end

  undef :width
  def width
    @width ||= @options[:max_width] || View.width
  end

  # find max length for each field; start with the headers
  def default_field_lengths
    field_lengths = @headers ? @headers.inject({}) {|h,(k,v)| h[k] = String.size(v); h} :
      @fields.inject({}) {|h,e| h[e] = 1; h }
    @rows.each do |row|
      @fields.each do |field|
        len = String.size(row[field])
        field_lengths[field] = len if len > field_lengths[field].to_i
      end
    end
    field_lengths
  end

  def set_filter_defaults(rows)
    @filter_classes.each do |klass, filter|
      @fields.each {|field|
        if rows.all? {|r| r[field].class == klass }
          @options[:filters][field] ||= filter
        end
      }
    end
  end

  def filter_values(rows)
    @filter_classes = Helpers::Table.filter_classes.merge @options[:filter_classes] || {}
    set_filter_defaults(rows) unless @options[:filter_any]
    rows.map {|row|
      @fields.inject({}) {|new_row,f|
        (filter = @options[:filters][f]) || (@options[:filter_any] && (filter = @filter_classes[row[f].class]))
        new_row[f] = filter ? call_filter(filter, row[f]) : row[f]
        new_row
      }
    }
  end

  def call_filter(filter, val)
    filter.is_a?(Proc) ? filter.call(val) :
      val.respond_to?(Array(filter)[0]) ? val.send(*filter) : Filters.send(filter, val)
  end

  def validate_values(rows)
    rows.each {|row|
      @fields.each {|f|
        row[f] = row[f].to_s || ''
        row[f] = row[f].gsub(/(\t|\r|\n)/) {|e| e.dump.gsub('"','') } if @options[:escape_special_chars]
      }
    }
  end

  # Converts an array to a hash mapping a numerical index to its array value.
  def array_to_indices_hash(array)
    array.inject({}) {|hash,e|  hash[hash.size] = e; hash }
  end
  #:startdoc:
end
end
