require File.join(File.dirname(__FILE__), 'test_helper')

class Hirb::UtilTest < Test::Unit::TestCase
  test "any_const_get returns nested class" do
    Hirb::Util.any_const_get("Test::Unit").should == ::Test::Unit
  end
  
  test "any_const_get returns nil for invalid class" do
    Hirb::Util.any_const_get("Basdfr").should == nil
  end
  
  test "any_const_get returns class when given class" do
    Hirb::Util.any_const_get(String).should == String
  end
end