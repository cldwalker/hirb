class Hirb::Helpers::TabTable < Hirb::Helpers::Table
  DELIM = "\t"

  # Renders a tab-delimited table
  def self.render(rows, options={})
    new(rows, {:description => false}.merge(options)).render
  end

  def render_header
    @headers ? render_table_header : []
  end

  def render_table_header
    [ format_values(@headers).join(DELIM) ]
  end

  def render_rows
    @rows.map { |row| format_values(row).join(DELIM) }
  end

  def render_footer
    []
  end
end
