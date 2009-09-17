require File.join(File.dirname(__FILE__), 'test_helper')

class HirbTest < Test::Unit::TestCase
  before(:each) {Hirb.instance_eval "@config = nil"}

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
    Hirb.expects(:read_config_file)
    Hirb.config(true)
  end

  test "config_file sets correctly when no ENV['HOME']" do
    Hirb.config_file = nil
    home = ENV.delete('HOME')
    Hirb.config_file.class.should == String
    ENV["HOME"] = home
  end
end