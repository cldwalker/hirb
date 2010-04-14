require File.join(File.dirname(__FILE__), 'test_helper')

describe "auto table" do
  it "converts nonarrays to arrays and renders" do
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
    Helpers::AutoTable.render(::Set.new([1,2,3])).should == expected_table
  end

  it "renders hash" do
    expected_table = <<-TABLE.unindent
    +---+-------+
    | 0 | 1     |
    +---+-------+
    | a | 12345 |
    +---+-------+
    1 row in set
    TABLE
    Helpers::AutoTable.render({:a=>12345}).should == expected_table
  end
end