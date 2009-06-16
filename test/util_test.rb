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

  test "choose_from_array specifies range with -" do
    Hirb::Util.choose_from_array([1,2,3,4], '1-2,4').should == [1,2,4]
  end

  test "choose_from_array specifies range with .." do
    Hirb::Util.choose_from_array([1,2,3,4], '1 .. 2,4').should == [1,2,4]
  end

  test "choose_from_array chooses all with *" do
    Hirb::Util.choose_from_array([1,2,3,4], '*').should == [1,2,3,4]
  end

  test "choose_from_array ignores non-numerical input" do
    Hirb::Util.choose_from_array([1,2,3,4], 'a,2').should == [2]
  end

  test "choose_from_array ignores 0" do
    Hirb::Util.choose_from_array([1,2,3,4], '0,2').should == [2]
  end

  test "choose_from_array returns empty when empty input" do
    Hirb::Util.choose_from_array([1,2,3,4], "\n").should == []
  end
end