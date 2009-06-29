require File.join(File.dirname(__FILE__), 'test_helper')

class Hirb::Helpers::ObjectTableTest < Test::Unit::TestCase
  context "object table" do
    before(:all) {
      @pets = [stub(:name=>'rufus', :age=>7, :to_s=>'rufus'), stub(:name=>'alf', :age=>101, :to_s=>'alf')]
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
    
    test "with no options defaults to to_s field" do
      expected_table = <<-TABLE.unindent
      +-------+
      | value |
      +-------+
      | rufus |
      | alf   |
      +-------+
      2 rows in set
      TABLE
      Hirb::Helpers::ObjectTable.render(@pets).should == expected_table
    end

    test "renders simple arrays" do
      expected_table = <<-TABLE.unindent
      +-------+
      | value |
      +-------+
      | 1     |
      | 2     |
      | 3     |
      | 4     |
      +-------+
      4 rows in set
      TABLE
      Hirb::Helpers::ObjectTable.render([1,2,3,4]).should == expected_table
    end
  end  
end