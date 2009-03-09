class Hirb::Helpers::ActiveRecordTable < Hirb::Helpers::ObjectTable
  # rows are activerecord objects, fields are any record attributes
  def self.render(rows, options={})
    rows = [rows] unless rows.is_a?(Array)
    options[:fields] ||= 
      begin
        fields = rows.first.attribute_names
        fields.unshift(fields.delete('id')) if fields.include?('id')
        fields
      end
    super(rows, options)
  end
end