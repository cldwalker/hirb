require File.join(File.dirname(__FILE__), 'test_helper')

describe "activerecord table" do
  it "with no select gets default options" do
    pet = stub(:name=>'rufus', :age=>7, :attributes=>{"name"=>'rufus', 'age'=>7}, :class=>stub(:column_names=>%w{age name}))
    Helpers::AutoTable.active_record__base_view(pet).should == {:fields=>[:age, :name]}
  end

  it "with select gets default options" do
    pet = stub(:name=>'rufus', :age=>7, :attributes=>{'name'=>'rufus'}, :class=>stub(:column_names=>%w{age name}))
    Helpers::AutoTable.active_record__base_view(pet).should == {:fields=>[:name]}
  end
end