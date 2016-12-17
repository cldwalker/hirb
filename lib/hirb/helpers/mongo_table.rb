# Creates a mongo table for support MongoDB's dynamic fields
class Hirb::Helpers::MongoTable < Hirb::Helpers::Table
  extend Hirb::DynamicView
  # output are any ruby objects. Takes same options as Hirb::Helpers::Table.render except as noted below.
  #
  # ==== Options:
  # [:fields] Methods of the object to represent as columns.
  def self.render(output, options ={})
    output = Array(output)
    (defaults = dynamic_options(output[0])) && (options = defaults.merge(options))
    item_hashes = options[:fields].empty? ? [] : Array(output).inject([]) {|t,item|
      t << options[:fields].inject({}) {|h,f| h[f] = item.__send__(f) rescue item.__send__("read_attribute", f); h}
    }
    super(item_hashes, options)
  end
end
