require File.join(File.dirname(__FILE__), 'test_helper')

class Hirb::Helpers::ActiveRecordTableTest < Test::Unit::TestCase
  context "activerecord table" do
    test "with no select renders" do
      expected_table = <<-TABLE.unindent
      +-----+-------+
      | age | name  |
      +-----+-------+
      | 7   | rufus |
      | 101 | alf   |
      +-----+-------+
      2 rows in set
      TABLE
      @pets = [stub(:name=>'rufus', :age=>7, :attributes=>{"name"=>'rufus', 'age'=>7}, :class=>stub(:column_names=>%w{age name})),
        stub(:name=>'alf', :age=>101)]
      Hirb::Helpers::ActiveRecordTable.render(@pets).should == expected_table
    end

    test "with select renders" do
      expected_table = <<-TABLE.unindent
      +-------+
      | name  |
      +-------+
      | rufus |
      | alf   |
      +-------+
      2 rows in set
      TABLE
      @pets = [stub(:name=>'rufus', :age=>7, :attributes=>{'name'=>'rufus'}, :class=>stub(:column_names=>%w{age name})),
        stub(:name=>'alf', :age=>101)]
      Hirb::Helpers::ActiveRecordTable.render(@pets).should == expected_table
    end
  end
end