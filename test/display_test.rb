require File.join(File.dirname(__FILE__), 'test_helper')

class Hirb::DisplayTest < Test::Unit::TestCase
  test "output_class_config recursively merges" do
    Hirb::Display.config = {"String"=>{:args=>[1,2]}, "Object"=>{:method=>:object_output}, "Kernel"=>{:method=>:default_output}}
    expected_result = {:method=>:object_output, :args=>[1, 2]}
    Hirb::Display.output_class_config(String).should == expected_result
  end
end
