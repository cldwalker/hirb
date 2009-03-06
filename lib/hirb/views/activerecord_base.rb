class Hirb::Views::ActiveRecord_Base
  def self.render(*args)
    Hirb::Helpers::ActiveRecordTable.render(*args)
  end
end