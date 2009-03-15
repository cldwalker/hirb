require File.join(File.dirname(__FILE__), 'test_helper')

class Hirb::Helpers::TableTest < Test::Unit::TestCase
  def table(*args)
    Hirb::Helpers::Table.render(*args)
  end
  
  context "basic table" do
    test "renders" do
      expected_table = <<-TABLE.unindent
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
    
    test "with no headers renders" do
      expected_table = <<-TABLE.unindent
      +---+---+
      | 1 | 2 |
      +---+---+
      1 row in set
      TABLE
      table([{:a=>1, :b=>2}], :headers=>nil).should == expected_table
    end

    test "with string keys renders" do
      expected_table = <<-TABLE.unindent
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
    
    test "with array only rows renders" do
      expected_table = <<-TABLE.unindent
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
    
    test "with too many fields raises error" do
      assert_raises(Hirb::Helpers::Table::TooManyFieldsForWidthError) { table([Array.new(70, 'AAA')]) }
    end
    
    test "with no rows renders" do
      table([]).should == "0 rows in set"
    end
  end

  context "table with" do
    test "fields option renders" do
      expected_table = <<-TABLE.unindent
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
    
    test "fields option and array only rows" do
      expected_table = <<-TABLE.unindent
      +---+---+
      | 0 | 2 |
      +---+---+
      | 1 | 3 |
      +---+---+
      1 row in set
      TABLE
      table([[1,2,3]], :fields=>[0,2]).should == expected_table
    end
  
    test "invalid fields option renders empty columns" do
      expected_table = <<-TABLE.unindent
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
  
    test "invalid fields in field_lengths option renders" do
      expected_table = <<-TABLE.unindent
      +------------+---+
      | a          | b |
      +------------+---+
      | AAAAAAA... | 2 |
      +------------+---+
      1 row in set
  TABLE
      table([{:a=> "A" * 50, :b=>2}], :field_lengths=>{:a=>10,:c=>10}).should == expected_table
    end
  
    test "field_lengths option and field_lengths less than 3 characters renders" do
      expected_table = <<-TABLE.unindent
      +----+---+
      | a  | b |
      +----+---+
      | AA | 2 |
      +----+---+
      1 row in set
  TABLE
      table([{:a=> "A" * 50, :b=>2}], :field_lengths=>{:a=>2}).should == expected_table
    end
  
    test "field_lengths option renders" do
      expected_table = <<-TABLE.unindent
      +------------+---+
      | a          | b |
      +------------+---+
      | AAAAAAA... | 2 |
      +------------+---+
      1 row in set
  TABLE
      table([{:a=> "A" * 50, :b=>2}], :field_lengths=>{:a=>10}).should == expected_table
    end
  
    test "max_width option renders" do
      expected_table = <<-TABLE.unindent
      +--------------------------+---+------------+
      | a                        | b | c          |
      +--------------------------+---+------------+
      | AAAAAAAAAAAAAAAAAAAAA... | 2 | CCCCCCCCCC |
      +--------------------------+---+------------+
      1 row in set
  TABLE
      table([{:a=> "A" * 50, :b=>2, :c=>"C"*10}], :max_width=>30).should == expected_table
    end

    test "max_width option nil renders full table" do
      expected_table = <<-TABLE.unindent
      +----------------------------------------------------+---+------------+
      | a                                                  | b | c          |
      +----------------------------------------------------+---+------------+
      | AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA | 2 | CCCCCCCCCC |
      +----------------------------------------------------+---+------------+
      1 row in set
  TABLE
      table([{:a=> "A" * 50, :b=>2, :c=>"C"*10}], :max_width=>nil).should == expected_table
    end
    
    test "global max_width renders" do
      expected_table = <<-TABLE.unindent
      +--------------------------+---+------------+
      | a                        | b | c          |
      +--------------------------+---+------------+
      | AAAAAAAAAAAAAAAAAAAAA... | 2 | CCCCCCCCCC |
      +--------------------------+---+------------+
      1 row in set
  TABLE
      Hirb::Helpers::Table.max_width = 30
      table([{:a=> "A" * 50, :b=>2, :c=>"C"*10}]).should == expected_table
      Hirb::Helpers::Table.max_width = Hirb::Helpers::Table::DEFAULT_MAX_WIDTH
    end

    test "headers option and headers longer than fields renders" do
      expected_table = <<-TABLE.unindent
      +---+---------+---------+
      | a | field B | field C |
      +---+---------+---------+
      | A | 2       | C       |
      +---+---------+---------+
      1 row in set
  TABLE
      table([{:a=> "A", :b=>2, :c=>"C"}], :headers=>{:b=>"field B", :c=>"field C"}).should == expected_table
    end
  
    test "headers option and headers shortened by field_lengths renders" do
      expected_table = <<-TABLE.unindent
      +-------+---+
      | fi... | b |
      +-------+---+
      | A     | 2 |
      +-------+---+
      1 row in set
  TABLE
      table([{:a=> "A", :b=>2}], :headers=>{:a=>"field A"}, :field_lengths=>{:a=>5}).should == expected_table
    end
    
    test "with headers option as an array renders" do
      expected_table = <<-TABLE.unindent
      +---+---+
      | A | B |
      +---+---+
      | 1 | 2 |
      | 3 | 4 |
      +---+---+
      2 rows in set
      TABLE
      table([[1,2], [3,4]], :headers=>['A', 'B']).should == expected_table
    end
    
  end
  
  context "object table" do
    before(:all) {
      @pets = [stub(:name=>'rufus', :age=>7), stub(:name=>'alf', :age=>101)]
    }
    test "renders" do
      expected_table = <<-TABLE.unindent
      +-------+-----+
      | name  | age |
      +-------+-----+
      | rufus | 7   |
      | alf   | 101 |
      +-------+-----+
      2 rows in set
      TABLE
      Hirb::Helpers::ObjectTable.render(@pets, :fields=>[:name, :age]).should == expected_table
    end
    
    test "with no options fields raises ArgumentError" do
      assert_raises(ArgumentError) { Hirb::Helpers::ObjectTable.render(@pets) }
    end
  end
  
  context "activerecord table" do
    before(:all) {
      @pets = [stub(:name=>'rufus', :age=>7, :attribute_names=>['age', 'name']), stub(:name=>'alf', :age=>101)]
    }
    test "renders" do
      expected_table = <<-TABLE.unindent
      +-----+-------+
      | age | name  |
      +-----+-------+
      | 7   | rufus |
      | 101 | alf   |
      +-----+-------+
      2 rows in set
      TABLE
      Hirb::Helpers::ActiveRecordTable.render(@pets).should == expected_table
    end
  end
  
  test "restrict_field_lengths handles many fields" do
    @table = Hirb::Helpers::Table.new([{:field1=>'f1', :field2=>'f2', :field3=>'f3'}])
    @table.restrict_field_lengths({:field1=>10, :field2=>15, :field3=>100}, 10)
  end
end