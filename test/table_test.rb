require File.join(File.dirname(__FILE__), 'test_helper')

class Hirb::Helpers::TableTest < Test::Unit::TestCase
  def table(*args)
    Hirb::Helpers::Table.render(*args)
  end
  
  test "basic table renders" do
    expected_table = <<TABLE.gsub(/^\s*/, '').chomp
    +---+---+
    | a | b |
    +---+---+
    | 1 | 2 |
    | 3 | 4 |
    +---+---+
    2 rows in set
TABLE
    table([{:a=>1, :b=>2}, {:a=>3, :b=>4}]).should == expected_table
  end
  
  test "basic table with no headers renders" do
    expected_table = <<TABLE.gsub(/^\s*/, '').chomp
    +---+---+
    | 1 | 2 |
    +---+---+
    1 row in set
TABLE
    table([{:a=>1, :b=>2}], :headers=>nil).should == expected_table
  end

  test "basic table with string keys renders" do
    expected_table = <<TABLE.gsub(/^\s*/, '').chomp
    +---+---+
    | a | b |
    +---+---+
    | 1 | 2 |
    | 3 | 4 |
    +---+---+
    2 rows in set
TABLE
    table([{'a'=>1, 'b'=>2}, {'a'=>3, 'b'=>4}]).should == expected_table
  end
  
  test "basic table with array rows renders" do
    expected_table = <<TABLE.gsub(/^\s*/, '').chomp
    +---+---+
    | 0 | 1 |
    +---+---+
    | 1 | 2 |
    | 3 | 4 |
    +---+---+
    2 rows in set
TABLE
    table([[1,2], [3,4]]).should == expected_table
  end
 
  test "table with fields option renders" do
    expected_table = <<TABLE.gsub(/^\s*/, '').chomp
    +---+---+
    | b | a |
    +---+---+
    | 2 | 1 |
    | 4 | 3 |
    +---+---+
    2 rows in set
TABLE
    table([{:a=>1, :b=>2}, {:a=>3, :b=>4}], :fields=>[:b, :a]).should == expected_table
  end
  
  test "table with invalid fields renders empty columns" do
    expected_table = <<TABLE.gsub(/^\s*/, '').chomp
    +---+---+
    | b | c |
    +---+---+
    | 2 |   |
    | 4 |   |
    +---+---+
    2 rows in set
TABLE
    table([{:a=>1, :b=>2}, {:a=>3, :b=>4}], :fields=>[:b, :c]).should == expected_table
  end
  
  test "table with invalid fields in field_lengths option renders" do
    expected_table = <<TABLE.gsub(/^\s*/, '').chomp
    +------------+---+
    | a          | b |
    +------------+---+
    | AAAAAAA... | 2 |
    +------------+---+
    1 row in set
TABLE
    table([{:a=> "A" * 50, :b=>2}], :field_lengths=>{:a=>10,:c=>10}).should == expected_table
  end
  
  test "table with field_lengths less than 3 characters renders" do
    expected_table = <<TABLE.gsub(/^\s*/, '').chomp
    +----+---+
    | a  | b |
    +----+---+
    | AA | 2 |
    +----+---+
    1 row in set
TABLE
    table([{:a=> "A" * 50, :b=>2}], :field_lengths=>{:a=>2}).should == expected_table
  end
  
  test "table with only some fields in field_lengths option renders" do
    expected_table = <<TABLE.gsub(/^\s*/, '').chomp
    +------------+---+
    | a          | b |
    +------------+---+
    | AAAAAAA... | 2 |
    +------------+---+
    1 row in set
TABLE
    table([{:a=> "A" * 50, :b=>2}], :field_lengths=>{:a=>10}).should == expected_table
  end
  
  test "table with max_width option renders" do
    expected_table = <<TABLE.gsub(/^\s*/, '').chomp
    +---------------------+---+------------+
    | a                   | b | c          |
    +---------------------+---+------------+
    | AAAAAAAAAAAAAAAA... | 2 | CCCCCCCCCC |
    +---------------------+---+------------+
    1 row in set
TABLE
    table([{:a=> "A" * 50, :b=>2, :c=>"C"*10}], :max_width=>30).should == expected_table
  end
  
  test "table with global max_width renders" do
    expected_table = <<TABLE.gsub(/^\s*/, '').chomp
    +---------------------+---+------------+
    | a                   | b | c          |
    +---------------------+---+------------+
    | AAAAAAAAAAAAAAAA... | 2 | CCCCCCCCCC |
    +---------------------+---+------------+
    1 row in set
TABLE
    Hirb::Helpers::Table.max_width = 30
    table([{:a=> "A" * 50, :b=>2, :c=>"C"*10}]).should == expected_table    
    Hirb::Helpers::Table.max_width = Hirb::Helpers::Table::DEFAULT_MAX_WIDTH
  end

  test "table with some headers and headers longer than fields renders" do
    expected_table = <<TABLE.gsub(/^\s*/, '').chomp
    +---+---------+---------+
    | a | field B | field C |
    +---+---------+---------+
    | A | 2       | C       |
    +---+---------+---------+
    1 row in set
TABLE
    table([{:a=> "A", :b=>2, :c=>"C"}], :headers=>{:b=>"field B", :c=>"field C"}).should == expected_table
  end
  
  test "table with headers longer than fields and headers shortened by field_lengths renders" do
    expected_table = <<TABLE.gsub(/^\s*/, '').chomp
    +-------+---+
    | fi... | b |
    +-------+---+
    | A     | 2 |
    +-------+---+
    1 row in set
TABLE
    table([{:a=> "A", :b=>2}], :headers=>{:a=>"field A"}, :field_lengths=>{:a=>5}).should == expected_table
  end    
  
  test "empty table renders" do
    table([]).should == "0 rows in set"
  end
end
