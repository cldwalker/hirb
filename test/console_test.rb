require File.join(File.dirname(__FILE__), 'test_helper')

class Hirb::ConsoleTest < Test::Unit::TestCase
  context "parse_input" do
    test "config is set if it wasn't before" do
      reset_config
      Hirb::View.expects(:render_output)
      Hirb::Console.render_output('blah')
      Hirb::View.config.is_a?(Hash).should == true
    end
  end
end