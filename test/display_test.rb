require File.join(File.dirname(__FILE__), 'test_helper')

# mocks IRB for testing
module ::IRB
  class Irb
    def initialize(context)
      @context = context
    end
    def output_value; end
  end
end

class Hirb::DisplayTest < Test::Unit::TestCase
  test "output_class_config recursively merges" do
    Hirb::Display.config = {"String"=>{:args=>[1,2]}, "Object"=>{:method=>:object_output}, "Kernel"=>{:method=>:default_output}}
    expected_result = {:method=>:object_output, :args=>[1, 2]}
    Hirb::Display.output_class_config(String).should == expected_result
  end
  
  test "output_class_config returns hash when nothing found" do
    Hirb::Display.config = {}
    Hirb::Display.output_class_config(String).should == {}
  end
  
  test "enable redefines output_value" do
    Hirb::Display.expects(:output_value).once
    Hirb::Display.enable
    context_stub = stub(:last_value=>'')
    ::IRB::Irb.new(context_stub).output_value
  end
  
  test "disable points output_value back to original output_value" do
    Hirb::Display.expects(:output_value).never
    Hirb::Display.enable
    Hirb::Display.disable
    context_stub = stub(:last_value=>'')
    ::IRB::Irb.new(context_stub).output_value
  end
  
  #test "calls original output_value if hirb display is nil"
  
  context "output_value" do
    before(:all) { Hirb::Display.enable }
    after(:all) { Hirb::Display.disable }
    
    test "formats with method option" do
      eval "module ::Kernel; def commify(string); string.split('').join(','); end; end"
      Hirb::Display.config = {"String"=>{:method=>:commify}}
      Hirb::Display.expects(:display_output).with('d,u,d,e')
      Hirb::Display.output_value('dude')
    end
    
    test "formats with class option" do
      eval "module ::Commify; def self.run(string); string.split('').join(','); end; end"
      Hirb::Display.config = {"String"=>{:class=>"Commify"}}
      Hirb::Display.expects(:display_output).with('d,u,d,e')
      Hirb::Display.output_value('dude')
    end
    
    test "formats with args option" do
      eval "module ::Blahify; def self.run(*args); end; end"
      Hirb::Display.config = {"String"=>{:class=>"Blahify", :args=>['a', 'b']}}
      Blahify.expects(:run).with('dude', 'a', 'b')
      Hirb::Display.output_value('dude')
    end
  end
end
