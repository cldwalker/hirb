class Hirb::Helpers::ObjectTable < Hirb::Helpers::Table
  # Rows are any ruby objects. Takes same options as Hirb::Helpers::Table.render except as noted below.
  #
  # Options:
  #   :fields- Methods of the object which are represented as columns in the table. Required option.
  #     All method values are converted to strings via to_s.
  def self.render(rows, options ={})
    raise(ArgumentError, "Option 'fields' is required.") unless options[:fields]
    rows = [rows] unless rows.is_a?(Array)
    item_hashes = rows.inject([]) {|t,item|
      t << options[:fields].inject({}) {|h,f| h[f] = item.send(f).to_s; h}
    }
    super(item_hashes, options)
  end
end