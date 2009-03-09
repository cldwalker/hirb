class Hirb::Helpers::ObjectTable < Hirb::Helpers::Table
  # rows is an array of ruby objects, fields are attributes of the given objects
  def self.render(rows, options ={})
    raise(ArgumentError, "Option 'fields' is required.") unless options[:fields]
    item_hashes = rows.inject([]) {|t,item|
      t << options[:fields].inject({}) {|h,f| h[f] = item.send(f).to_s; h}
    }
    super(item_hashes, options)
  end
end