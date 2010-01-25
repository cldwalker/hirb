require File.join(File.dirname(__FILE__), 'test_helper')

class HirbTest < Test::Unit::TestCase
  before(:all) { Hirb.config_files = nil }
  before(:each) { Hirb.config = nil }

  test "config converts yaml when config file exists" do
    yaml_data = {:blah=>'blah'}
    File.stubs('exists?').returns(true)
    YAML::expects(:load_file).returns(yaml_data)
    Hirb.config.should == yaml_data
  end
  
  test "config defaults to hash when no config file" do
    File.stubs('exists?').returns(false)
    Hirb.config.should == {}
  end
  
  test "config reloads if given explicit reload" do
    Hirb.config
    Hirb.expects(:read_config_file).returns({})
    Hirb.config(true)
  end

  test "config reads multiple config files and merges them" do
    Hirb.config_files = %w{one two}
    Hirb.expects(:read_config_file).times(2).returns({:output=>{"String"=>:auto_table}}, {:output=>{"Array"=>:auto_table}})
    Hirb.config.should == {:output=>{"Array"=>:auto_table, "String"=>:auto_table}}
    Hirb.config_files = nil
  end

  test "config_file sets correctly when no ENV['HOME']" do
    Hirb.config_file = nil
    home = ENV.delete('HOME')
    Hirb.config_file.class.should == String
    ENV["HOME"] = home
  end
end