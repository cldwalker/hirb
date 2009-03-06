require File.join(File.dirname(__FILE__), 'test_helper')

class Hirb::ImportTest < Test::Unit::TestCase
  test "including Hirb::Console extends Object" do
    Object.ancestors.map {|e| e.to_s}.include?("Hirb::Console").should be(false)
    Object.send :include, Hirb::Console
    Object.ancestors.map {|e| e.to_s}.include?("Hirb::Console").should be(true)
  end
  
  test "require import_object_view extends Object" do
    Object.ancestors.map {|e| e.to_s}.include?("Hirb::ObjectMethods").should be(false)
    require 'hirb/import_object'
    Object.ancestors.map {|e| e.to_s}.include?("Hirb::ObjectMethods").should be(true)
  end
end
