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

    test "converts hash with any value hashes to inspected values" do
      expected_table = <<-TABLE.unindent
      +---+---------+
      | 0 | 1       |
      +---+---------+
      | c | "ok"    |
      | a | {:b=>1} |
      +---+---------+
      2 rows in set
      TABLE
      Hirb::Helpers::AutoTable.render({:a=>{:b=>1}, :c=>'ok'}).should == expected_table
    end

    test "doesn't convert hash with value hashes if filter exists for value" do
      expected_table = <<-TABLE.unindent
      +------+-------+
      | name | value |
      +------+-------+
      | c    | ok    |
      | a    | b1    |
      +------+-------+
      2 rows in set
      TABLE
      Hirb::Helpers::AutoTable.render({:a=>{:b=>1}, :c=>'ok'}, :change_fields=>['name', 'value'],
       :filters=>{'value'=>:to_s}).should == expected_table
    end
  end
end