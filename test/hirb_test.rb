require File.join(File.dirname(__FILE__), 'test_helper')

describe "Hirb" do
  before_all { Hirb.config_files = nil }
  before { Hirb.config = nil }

  it "config converts yaml when config file exists" do
    yaml_data = {:blah=>'blah'}
    File.stubs('exist?').returns(true)
    Hirb.config_files = ['ok']
    YAML.expects(:load_file).returns(yaml_data)
    Hirb.config.should == yaml_data
  end

  it "config defaults to hash when no config file" do
    File.stubs('exist?').returns(false)
    Hirb.config.should == {}
  end

  it "config reloads if given explicit reload" do
    Hirb.config
    Hirb.expects(:read_config_file).returns({})
    Hirb.config(true)
  end

  it "config reads multiple config files and merges them" do
    Hirb.config_files = %w{one two}
    Hirb.expects(:read_config_file).times(2).returns({:output=>{"String"=>:auto_table}}, {:output=>{"Array"=>:auto_table}})
    Hirb.config.should == {:output=>{"Array"=>:auto_table, "String"=>:auto_table}}
    Hirb.config_files = nil
  end

  it "config_file sets correctly when no ENV['HOME']" do
    Hirb.config_files = nil
    home = ENV.delete('HOME')
    Hirb.config_files[0].class.should == String
    ENV["HOME"] = home
  end
end
