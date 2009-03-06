class Hirb::Helpers::ObjectTable < Hirb::Helpers::Table
  # items is an array of ruby objects, fields are attributes of the given objects
  def self.render(items, options ={})
    raise(ArgumentError, "Option 'fields' is required.") unless options[:fields]
    item_hashes = items.inject([]) {|t,item|
      t << options[:fields].inject({}) {|h,f| h[f] = item.send(f).to_s; h}
    }
    super(item_hashes, options)
  end
end