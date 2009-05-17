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
    super(rows, options)
  end
end
