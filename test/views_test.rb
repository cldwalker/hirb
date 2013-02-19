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

describe "mongoid table" do
  it "only has one _id" do
    fields = {'_id' => 'x0f0x', 'name' => 'blah'}
    dynamic_fields = {'test' => 'footbar'}
    mongoid_stub = stub(:class => stub(:fields => fields), :attributes => fields.merge(dynamic_fields))
    Helpers::MongoTable.mongoid__document_view(mongoid_stub).should ==
      {:fields => (fields.keys | dynamic_fields.keys).sort }
  end
end
