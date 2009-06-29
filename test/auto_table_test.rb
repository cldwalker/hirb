require File.join(File.dirname(__FILE__), 'test_helper')

class Hirb::Helpers::AutoTableTest < Test::Unit::TestCase
  context "auto table" do
    test "converts nonarrays to arrays and renders" do
      require 'set'
      expected_table = <<-TABLE.unindent
      +-------+
      | value |
      +-------+
      | 1     |
      | 2     |
      | 3     |
      +-------+
      3 rows in set
      TABLE
      Hirb::Helpers::AutoTable.render(::Set.new([1,2,3])).should == expected_table
    end
  end
end