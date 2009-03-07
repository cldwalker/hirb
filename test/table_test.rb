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
  
  test "table with field_lengths option renders" do
    expected_table = <<TABLE.gsub(/^\s*/, '').chomp
    +------------+------------+
    | a          | b          |
    +------------+------------+
    | AAAAAAA... | 2          |
    +------------+------------+
    1 row in set
TABLE
    table([{:a=> "A" * 50, :b=>2}], :field_lengths=>{:a=>10,:b=>10}).should == expected_table
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
    Hirb::Helpers::Table.max_width = 150
  end
  
  test "empty table renders" do
    table([]).should == "0 rows in set"
  end
end
