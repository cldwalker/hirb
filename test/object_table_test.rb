require File.join(File.dirname(__FILE__), 'test_helper')

describe "object table" do
  def table(*args)
    Helpers::ObjectTable.render(*args)
  end

  before_all {
    @pets = [stub(:name=>'rufus', :age=>7, :to_s=>'rufus'), stub(:name=>'alf', :age=>101, :to_s=>'alf')]
  }
  it "renders" do
    expected_table = <<-TABLE.unindent
    +-------+-----+
    | name  | age |
    +-------+-----+
    | rufus | 7   |
    | alf   | 101 |
    +-------+-----+
    2 rows in set
    TABLE
    table(@pets, :fields=>[:name, :age]).should == expected_table
  end
  
  it "with no options defaults to to_s field" do
    expected_table = <<-TABLE.unindent
    +-------+
    | value |
    +-------+
    | rufus |
    | alf   |
    +-------+
    2 rows in set
    TABLE
    table(@pets).should == expected_table
  end

  it "renders simple arrays" do
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
    table([1,2,3,4]).should == expected_table
  end

  it "renders simple arrays with custom header" do
    expected_table = <<-TABLE.unindent
    +-----+
    | num |
    +-----+
    | 1   |
    | 2   |
    | 3   |
    | 4   |
    +-----+
    4 rows in set
    TABLE
    table([1,2,3,4], :headers=>{:to_s=>'num'}).should == expected_table
  end

  it "with empty fields" do
    expected_table = <<-TABLE.unindent
    0 rows in set
    TABLE
    table(@pets, :fields => []).should == expected_table
  end

  it "doesn't raise error for objects that don't have :send defined" do
    object = Object.new
    class<<object; self; end.send :undef_method, :send
    should.not.raise(NoMethodError) { table([object], :fields=>[:to_s]) }
  end
end