require 'rubygems'
require 'test/unit'
require 'context' #gem install jeremymcanally-context -s http://gems.github.com
require 'matchy' #gem install jeremymcanally-matchy -s http://gems.github.com
require 'mocha'
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
require 'hirb'

class Test::Unit::TestCase
  def capture_stdout(&block)
    original_stdout = $stdout
    $stdout = fake = StringIO.new
    begin
      yield
    ensure
      $stdout = original_stdout
    end
    fake.string
  end
end

class String
  def unindent(num=nil)
    regex = num ? /^\s{#{num}}/ : /^\s*/
    gsub(regex, '').chomp
  end
end