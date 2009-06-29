class Hirb::Helpers::ActiveRecordTable < Hirb::Helpers::ObjectTable
  # Rows are Rails' ActiveRecord::Base objects.
  # Takes same options as Hirb::Helpers::Table.render except as noted below.
  #
  # Options:
  #   :fields- Can be any attribute, column or not. If not given, this defaults to the database table's columns.
  def self.render(rows, options={})
    rows = [rows] unless rows.is_a?(Array)
    options[:fields] ||= 
      begin
        fields = rows.first.class.column_names
        fields.map {|e| e.to_sym }
      end
    if query_used_select?(rows)
      selected_columns = rows.first.attributes.keys
      sorted_columns = rows.first.class.column_names.dup.delete_if {|e| !selected_columns.include?(e) }
      sorted_columns += (selected_columns - sorted_columns)
      options[:fields] = sorted_columns.map {|e| e.to_sym}
    end
    super(rows, options)
  end

  def self.query_used_select?(rows) #:nodoc:
    rows.first.attributes.keys.sort != rows.first.class.column_names.sort
  end
end
