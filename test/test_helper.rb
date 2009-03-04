require 'rubygems'
require 'test/unit'
require 'context' #gem install jeremymcanally-context -s http://gems.github.com
require 'matchy' #gem install jeremymcanally-matchy -s http://gems.github.com
require 'stump' #gem install jeremymcanally-stump -s http://gems.github.com
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
require 'hirb'

class Test::Unit::TestCase
end

#from ActiveSupport
class Hash
  def slice(*keys)
    reject { |key| !keys.include?(key) }
  end
end
