class Hirb::Views::ActiveRecord_Base #:nodoc:
  def self.default_options
    {:ancestor=>true}
  end
  
  def self.render(*args)
    Hirb::Helpers::ActiveRecordTable.render(*args)
  end
end