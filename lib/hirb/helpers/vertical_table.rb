class Hirb::Helpers::VerticalTable < Hirb::Helpers::Table

  # Renders a vertical table using the same options as Hirb::Helpers::Table.render except for the ones below
  # and :max_fields, :vertical and :max_width which aren't used.
  # ==== Options:
  # [:hide_empty] Boolean which hides empty values (nil or '') from being displayed. Default is false.
  def self.render(rows, options={})
    new(rows, {:escape_special_chars=>false, :resize=>false}.merge(options)).render
  end

  #:stopdoc:
  def setup_field_lengths
    @field_lengths = default_field_lengths
  end

  def render_header; []; end
  def render_footer; []; end

  def render_rows
    i = 0
    longest_header = Hirb::String.size @headers.values.sort_by {|e| Hirb::String.size(e) }.last
    stars = "*" * [(longest_header + (longest_header / 2)), 3].max
    @rows.map do |row|
      row = "#{stars} #{i+1}. row #{stars}\n" +
      @fields.map {|f|
        if !@options[:hide_empty] || (@options[:hide_empty] && !row[f].empty?)
          "#{Hirb::String.rjust(@headers[f], longest_header)}: #{row[f]}"
        else
          nil
        end
      }.compact.join("\n")
      i+= 1
      row
    end
  end
  #:startdoc:
end