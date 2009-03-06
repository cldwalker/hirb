class Hirb::Views::ActiveRecord_Base
  def self.render(*args)
    Hirb::Helper::ActiveRecordTable.render(*args)
  end
end