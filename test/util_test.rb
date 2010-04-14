require File.join(File.dirname(__FILE__), 'test_helper')

describe "Util" do
  it "camelize converts underscore lowercase to camelcase" do
    Util.camelize('hirb/util').should == "Hirb::Util"
    Util.camelize('hirb_hash').should == "HirbHash"
  end

  it "any_const_get returns nested class" do
    Util.any_const_get("YAML::BaseNode").should == ::YAML::BaseNode
  end

  it "any_const_get returns nil for invalid class" do
    Util.any_const_get("Basdfr").should == nil
  end

  it "any_const_get returns class when given class" do
    Util.any_const_get(String).should == String
  end

  it "recursive_hash_merge merges" do
    expected_hash = {:output=>{:fields=>["f1", "f2"], :method=>"blah"}, :key1=>"hash1", :key2=>"hash2"}
    Util.recursive_hash_merge({:output=>{:fields=>%w{f1 f2}}, :key1=>'hash1'},
      {:output=>{:method=>'blah'}, :key2=>'hash2'}).should == expected_hash
  end

  it "choose_from_array specifies range with -" do
    Util.choose_from_array([1,2,3,4], '1-2,4').should == [1,2,4]
  end

  it "choose_from_array specifies range with .." do
    Util.choose_from_array([1,2,3,4], '1 .. 2,4').should == [1,2,4]
  end

  it "choose_from_array chooses all with *" do
    Util.choose_from_array([1,2,3,4], '*').should == [1,2,3,4]
  end

  it "choose_from_array ignores non-numerical input" do
    Util.choose_from_array([1,2,3,4], 'a,2').should == [2]
  end

  it "choose_from_array ignores 0" do
    Util.choose_from_array([1,2,3,4], '0,2').should == [2]
  end

  it "choose_from_array returns empty when empty input" do
    Util.choose_from_array([1,2,3,4], "\n").should == []
  end

  it "choose_from_array returns empty with an invalid range" do
    Util.choose_from_array([1,2,3,4], "5").should == []
  end

  it "capture_stdout" do
    string = "sweetness man"
    Util.capture_stdout { puts string }.should == string + "\n"
  end
end