require File.join(File.dirname(__FILE__), 'test_helper')

describe "mongo table" do
  def table(*args)
    Helpers::MongoTable.render(*args)
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
