require 'bacon'
require 'bacon/bits'
require 'mocha'
require 'mocha-on-bacon'
require 'hirb'
include Hirb

module TestHelpers
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
    View.instance_eval "@config = nil"
  end
end

class Bacon::Context
  include TestHelpers
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
