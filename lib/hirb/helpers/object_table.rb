class Hirb::Helpers::ObjectTable < Hirb::Helpers::Table
  # Rows are any ruby objects. Takes same options as Hirb::Helpers::Table.render except as noted below.
  #
  # Options:
  #   :fields- Methods of the object to represent as columns. Defaults to [:to_s].
  def self.render(rows, options ={})
    options[:fields] ||= [:to_s]
    options[:headers] = {:to_s=>'value'} if options[:fields] == [:to_s]
    rows = [rows] unless rows.is_a?(Array)
    item_hashes = rows.inject([]) {|t,item|
      t << options[:fields].inject({}) {|h,f| h[f] = item.send(f); h}
    }
    super(item_hashes, options)
  end
end