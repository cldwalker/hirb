require 'rubygems'
require 'test/unit'
require 'context' #gem install jeremymcanally-context -s http://gems.github.com
require 'matchy' #gem install jeremymcanally-matchy -s http://gems.github.com
require 'mocha'
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
require 'hirb'

class Test::Unit::TestCase
  # set these to avoid invoking stty multiple times which doubles test suite running time
  ENV["LINES"] = ENV["COLUMNS"] = "20"
  def reset_terminal_size
    ENV["LINES"] = ENV["COLUMNS"] = "20"
  end

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

  def capture_stderr(&block)
    original_stderr = $stderr
    $stderr = fake = StringIO.new
    begin
      yield
    ensure
      $stderr = original_stderr
    end
    fake.string
  end

  def reset_config
    Hirb::View.instance_eval "@config = nil"
  end
end

class String
  def unindent(num=nil)
    regex = num ? /^\s{#{num}}/ : /^\s*/
    gsub(regex, '').chomp
  end
end

# mocks IRB for View + Pager
module ::IRB
  class Irb
    def initialize(context)
      @context = context
    end
    def output_value; end
  end
end