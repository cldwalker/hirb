require File.join(File.dirname(__FILE__), 'test_helper')

describe "Console" do
  it "#table is called without Hirb enabled" do
    extend Hirb::Console
    reset_config
    expected_table = <<-TABLE.unindent
    +-------+
    | value |
    +-------+
    | 5     |
    | 3     |
    +-------+
    2 rows in set
    TABLE
    capture_stdout {
      table([5,3], :fields=>[:to_s])
    }.should == expected_table +"\n"
  end

  it ".render_output sets config if it wasn't before" do
    reset_config
    View.expects(:render_output)
    Console.render_output('blah')
    View.config.is_a?(Hash).should == true
  end
end
