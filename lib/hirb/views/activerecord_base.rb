class Hirb::Views::ActiveRecord_Base #:nodoc:
  def self.render(*args)
    Hirb::Helpers::ActiveRecordTable.render(*args)
  end
end