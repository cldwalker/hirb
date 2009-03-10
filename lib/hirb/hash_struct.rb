require 'ostruct'

class Hirb::HashStruct < OpenStruct #:nodoc:
  def self.block_to_hash(block=nil)
    config = self.new
    if block
      block.call(config)
      config.to_hash
    else
      {}
    end
  end

  def to_hash
    @table
  end
end