require File.join(File.dirname(__FILE__), 'test_helper')

class Hirb::ConsoleTest < Test::Unit::TestCase
  context "parse_input" do
    before(:each) { reset_config }
    test "config is set if it wasn't before" do
      Hirb::View.expects(:render_output)
      Hirb::Console.render_output('blah')
      Hirb::View.config.is_a?(Hash).should == true
    end

    test "convert symbol to :class option" do
      Hirb::View.expects(:render_output).with('blah', :class=>"Hirb::Helpers::Table", :options=>{})
      Hirb::Console.render_output('blah', :table)
    end

    test "passes all options except for formatter options into :options" do
      options = {:class=>'blah', :method=>'blah', :output_method=>'blah', :blah=>'blah'}
      expected_options = {:class=>'blah', :method=>'blah', :output_method=>'blah', :options=>{:blah=>'blah'}}
      Hirb::View.expects(:render_output).with('blah', expected_options)
      Hirb::Console.render_output('blah', options)
    end
  end
end