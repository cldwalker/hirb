require File.join(File.dirname(__FILE__), 'test_helper')

describe "auto table" do
  it "converts nonarrays to arrays and renders" do
    require 'set'
    # rubinius sorts Set#to_a differently
    arr = RUBY_DESCRIPTION.include?('rubinius') ? Set.new([1,2,3]).to_a : [1,2,3]

    expected_table = <<-TABLE.unindent
    +-------+
    | value |
    +-------+
    | #{arr[0]}     |
    | #{arr[1]}     |
    | #{arr[2]}     |
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
