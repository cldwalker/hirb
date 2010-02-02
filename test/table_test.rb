require File.join(File.dirname(__FILE__), 'test_helper')

class Hirb::Helpers::TableTest < Test::Unit::TestCase
  def table(*args)
    Hirb::Helpers::Table.render(*args)
  end
  before(:all) { reset_config }
  
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

    test "with too many fields defaults to vertical table" do
      rows = [Array.new(25, "A"* 10)]
      Hirb::Helpers::VerticalTable.expects(:render).with(rows, anything)
      capture_stderr { table(rows)}.should =~ /Error/
    end

    test "with no rows renders" do
      table([]).should == "0 rows in set"
    end

    test "renders utf8" do
      expected_table = <<-TABLE.unindent
      +--------------------+
      | name               |
      +--------------------+
      | ｱｲｳｴｵｶｷ            |
      | ｸｹｺｻｼｽｾｿﾀﾁﾂﾃ       |
      | Tata l'asticote    |
      | toto létoile PAOLI |
      +--------------------+
      4 rows in set
      TABLE
      table([{:name=>"ｱｲｳｴｵｶｷ"}, {:name=>"ｸｹｺｻｼｽｾｿﾀﾁﾂﾃ"}, {:name=>"Tata l'asticote"}, {:name=>"toto létoile PAOLI"}]).should == expected_table
    end

    test "with newlines renders with newlines stringified" do
      expected_table = <<-TABLE.unindent
      +-----+---+
      | a   | b |
      +-----+---+
      | 1#{'\n'} | 2 |
      | 3   | 4 |
      +-----+---+
      2 rows in set
      TABLE
      table([{'a'=>"1\n", 'b'=>2}, {'a'=>3, 'b'=>4}]).should == expected_table
    end

    test "with a field of only array values renders values comma joined" do
      expected_table = <<-TABLE.unindent
      +----+------+
      | a  | b    |
      +----+------+
      | 12 | 1, 2 |
      | ok | 3, 4 |
      +----+------+
      2 rows in set
      TABLE
      # depends on 1.8 Array#to_s
      table([{:a=>[1,2], :b=>[1,2]}, {:a=>'ok', :b=>[3,4]}]).should == expected_table
    end

    test "with filter class default doesn't override explicit filters" do
      expected_table = <<-TABLE.unindent
      +------+-------+
      | name | value |
      +------+-------+
      | a    | b1    |
      +------+-------+
      1 row in set
      TABLE
      table([{:name=>'a', :value=>{:b=>1}}], :filters=>{:value=>:to_s}).should == expected_table
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

    test "fields and number options copies fields option and does not modify it" do
      options = {:fields=>[:f1], :number=>true}
      table({:f1=>1, :f2=>2}, options)
      options[:fields].should == [:f1]
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
      +-----------+---+-----------+
      | a         | b | c         |
      +-----------+---+-----------+
      | AAAAAA... | 2 | CCCCCC... |
      +-----------+---+-----------+
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
    
    test "global width renders" do
      expected_table = <<-TABLE.unindent
      +-----------+---+-----------+
      | a         | b | c         |
      +-----------+---+-----------+
      | AAAAAA... | 2 | CCCCCC... |
      +-----------+---+-----------+
      1 row in set
      TABLE
      Hirb::View.load_config
      Hirb::View.resize(30)
      table([{:a=> "A" * 50, :b=>2, :c=>"C"*10}]).should == expected_table
      reset_config
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
    
    test "headers option as an array renders" do
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

    test "header_filter option renders" do
      expected_table = <<-TABLE.unindent
      +---+---+
      | A | B |
      +---+---+
      | 2 | 3 |
      +---+---+
      1 row in set
      TABLE
      table([{:a=> 2, :b=>3}], :header_filter=>:capitalize).should == expected_table
    end

    test "filters option renders" do
      expected_table = <<-TABLE.unindent
      +-----------+---+
      | 0         | 1 |
      +-----------+---+
      | s,o,m,e   | 2 |
      | t,h,i,n,g | 1 |
      +-----------+---+
      2 rows in set
      TABLE
      table([['some', {:num=>2}], ['thing', {:num=>1}]], :filters=>{0=>lambda {|e| e.split("").join(",")},
        1=>[:[], :num]}).should == expected_table
    end

    test "filters option calls Filters method and renders" do
      module ::Hirb::Helpers::Table::Filters
        def semicolon_join(arr); arr.join('; '); end
      end

      expected_table = <<-TABLE.unindent
      +------+------------------------------+
      | 0    | 1                            |
      +------+------------------------------+
      | some | unsightly; unreadable; array |
      +------+------------------------------+
      1 row in set
      TABLE
      table([[['some'], %w{unsightly unreadable array}]], :filters=>{1=>:semicolon_join}).should == expected_table
    end

    test "number option renders" do
      expected_table = <<-TABLE.unindent
      +--------+---+---+
      | number | 0 | 1 |
      +--------+---+---+
      | 1      | a | b |
      | 2      | c | d |
      +--------+---+---+
      2 rows in set
      TABLE
      table([['a','b'], ['c', 'd']], :number=>true).should == expected_table
    end

    test "description option false renders" do
      expected_table = <<-TABLE.unindent
      +---+---+
      | 0 | 1 |
      +---+---+
      | a | b |
      | c | d |
      +---+---+
      TABLE
      table([['a','b'], ['c', 'd']], :description=>false).should == expected_table
    end

    test "vertical option renders vertical table" do
      expected_table = <<-TABLE.unindent
      *** 1. row ***
      a: 1
      b: 2
      *** 2. row ***
      a: 3
      b: 4
      2 rows in set
      TABLE
      table([{:a=>1, :b=>2}, {:a=>3, :b=>4}], :vertical=>true).should == expected_table
    end

    test "vertical option renders vertical table with newlines" do
      expected_table = <<-TABLE.unindent
      *** 1. row ***
      a: 1
      b: 2
      *** 2. row ***
      a: 3
      b: 4
      and one
      2 rows in set
      TABLE
      table([{:a=>1, :b=>2}, {:a=>3, :b=>"4\nand one"}], :vertical=>true).should == expected_table
    end

    test "vertical option renders vertical table successively" do
      expected_table = <<-TABLE.unindent
      *** 1. row ***
      a: 1
      b: 2
      *** 2. row ***
      a: 3
      b: 4
      2 rows in set
      TABLE
      options = {:vertical=>true}
      table([{:a=>1, :b=>2}, {:a=>3, :b=>4}], options).should == expected_table
      table([{:a=>1, :b=>2}, {:a=>3, :b=>4}], options).should == expected_table
    end

    test "hide_empty and vertical options renders" do
      expected_table = <<-TABLE.unindent
      *** 1. row ***
      b: 2
      *** 2. row ***
      a: 3
      2 rows in set
      TABLE
      table([{:a=>'', :b=>2}, {:a=>3, :b=>nil}], :hide_empty=>true, :vertical=>true).should == expected_table
    end

    test "all_fields option renders all fields" do
      expected_table = <<-TABLE.unindent
      +---+---+---+
      | a | b | c |
      +---+---+---+
      | 1 | 2 |   |
      | 3 |   | 4 |
      +---+---+---+
      2 rows in set
      TABLE
      table([{:a=>1, :b=>2}, {:a=>3, :c=>4}], :all_fields=>true).should == expected_table
    end

    test "change_fields option renders" do
      expected_table = <<-TABLE.unindent
      +------+-------+
      | name | value |
      +------+-------+
      | 1    | 2     |
      | 2    | 3     |
      +------+-------+
      2 rows in set
      TABLE
      table([[1,2],[2,3]], :change_fields=>{0=>'name', 1=>'value'}).should == expected_table
      table([[1,2],[2,3]], :change_fields=>['name', 'value']).should == expected_table
    end

    test "return_rows option returns rows" do
      table([[1,2],[2,3]], :return_rows=>true).should == [{0=>"1", 1=>"2"}, {0=>"2", 1=>"3"}]
    end

    test "filter_values option filters values per value" do
      expected_table = <<-TABLE.unindent
      +---------+
      | a       |
      +---------+
      | {:b=>1} |
      | 2       |
      +---------+
      2 rows in set
      TABLE
      table([{:a=>{:b=>1}}, {:a=>2}], :filter_values=>true).should == expected_table
    end

    test "filter_classes option overrides class-wide filter_classes" do
      expected_table = <<-TABLE.unindent
      +----+
      | a  |
      +----+
      | b1 |
      +----+
      1 row in set
      TABLE
      table([{:a=>{:b=>1}}], :filter_classes=>{Hash=>:to_s}).should == expected_table
    end
  end

  context "table with callbacks" do
    before(:all) {
      Hirb::Helpers::Table.send(:define_method, :and_one_callback) do |obj, opt|
        obj.each {|row| row.each {|k,v| row[k] += opt[:add] } }
        obj
      end
    }
    after(:all) { Hirb::Helpers::Table.send(:remove_method, :and_one_callback) }

    test "detects and runs them" do
      expected_table = <<-TABLE.unindent
      +---+---+
      | a | b |
      +---+---+
      | 2 | 3 |
      | 4 | 5 |
      +---+---+
      2 rows in set
      TABLE
      table([{'a'=>1, 'b'=>2}, {'a'=>3, 'b'=>4}], :add=>1).should == expected_table
    end

    test "doesn't run callbacks in delete_callbacks option" do
      Hirb::Helpers::Table.send(:define_method, :and_two_callback) do |obj, opt|
        obj.each {|row| row.each {|k,v| row[k] = row[k] * 2 } }
        obj
      end

      expected_table = <<-TABLE.unindent
      +---+---+
      | a | b |
      +---+---+
      | 2 | 3 |
      | 4 | 5 |
      +---+---+
      2 rows in set
      TABLE
      table([{'a'=>1, 'b'=>2}, {'a'=>3, 'b'=>4}], :add=>1, :delete_callbacks=>[:and_two]).should == expected_table

      Hirb::Helpers::Table.send(:remove_method, :and_two_callback)
    end
  end
end