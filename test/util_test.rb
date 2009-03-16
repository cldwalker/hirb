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
  
  test "recursive_hash_merge merges" do
    expected_hash = {:output=>{:fields=>["f1", "f2"], :method=>"blah"}, :key1=>"hash1", :key2=>"hash2"}
    Hirb::Util.recursive_hash_merge({:output=>{:fields=>%w{f1 f2}}, :key1=>'hash1'},
      {:output=>{:method=>'blah'}, :key2=>'hash2'}).should == expected_hash
  end
end