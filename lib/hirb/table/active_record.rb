class Hirb::Table::ActiveRecord < Hirb::Table::Object
  # items are activerecord objects, fields are any record attributes
  def self.run(items, fields=[])
    items = [items] unless items.is_a?(Array)
    fields = items.first.attribute_names unless fields.any?
    fields = fields.map {|e| e.to_sym}
    fields.unshift(fields.delete(:id)) if fields.include?(:id)
    super(items, fields)
  end
end