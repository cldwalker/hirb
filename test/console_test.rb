require File.join(File.dirname(__FILE__), 'test_helper')

describe "parse_input" do
  it "config is set if it wasn't before" do
    reset_config
    View.expects(:render_output)
    Console.render_output('blah')
    View.config.is_a?(Hash).should == true
  end
end
