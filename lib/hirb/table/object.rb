class Hirb::Table::Object < Hirb::Table  
  # items is an array of ruby objects, fields are attributes of the given objects
  def self.run(items, fields, options={})
    item_hashes = items.inject([]) {|t,item|
      t << fields.inject({}) {|h,f| h[f] = item.send(f).to_s; h}
    }
    super(item_hashes, options.update(:fields=>fields))
  end
end