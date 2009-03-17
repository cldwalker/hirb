require 'rubygems'
require 'test/unit'
require 'context' #gem install jeremymcanally-context -s http://gems.github.com
require 'matchy' #gem install jeremymcanally-matchy -s http://gems.github.com
require 'mocha'
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
require 'hirb'

class Test::Unit::TestCase
end

class String
  def unindent(num=nil)
    regex = num ? /^\s{#{num}}/ : /^\s*/
    gsub(regex, '').chomp
  end
end