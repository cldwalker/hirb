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

class Hirb::ViewTest < Test::Unit::TestCase
  test "output_class_options recursively merges" do
    Hirb::View.config = {"String"=>{:args=>[1,2]}, "Object"=>{:method=>:object_output}, "Kernel"=>{:method=>:default_output}}
    expected_result = {:method=>:object_output, :args=>[1, 2]}
    Hirb::View.output_class_options(String).should == expected_result
  end
  
  test "output_class_options returns hash when nothing found" do
    Hirb::View.config = {}
    Hirb::View.output_class_options(String).should == {}
  end
  
  test "enable redefines output_value" do
    Hirb::View.expects(:output_value).once
    Hirb::View.enable
    context_stub = stub(:last_value=>'')
    ::IRB::Irb.new(context_stub).output_value
  end
  
  test "disable points output_value back to original output_value" do
    Hirb::View.expects(:output_value).never
    Hirb::View.enable
    Hirb::View.disable
    context_stub = stub(:last_value=>'')
    ::IRB::Irb.new(context_stub).output_value
  end
  
  #test "calls original output_value if hirb view is nil"
  
  context "output_value" do
    before(:all) { Hirb::View.enable }
    after(:all) { Hirb::View.disable }
    
    test "formats with method option" do
      eval "module ::Kernel; def commify(string); string.split('').join(','); end; end"
      Hirb::View.config = {"String"=>{:method=>:commify}}
      Hirb::View.expects(:view_output).with('d,u,d,e')
      Hirb::View.output_value('dude')
    end
    
    test "formats with class option" do
      eval "module ::Commify; def self.render(string); string.split('').join(','); end; end"
      Hirb::View.config = {"String"=>{:class=>"Commify"}}
      Hirb::View.expects(:view_output).with('d,u,d,e')
      Hirb::View.output_value('dude')
    end
    
    test "formats with option options" do
      eval "module ::Blahify; def self.render(*args); end; end"
      Hirb::View.config = {"String"=>{:class=>"Blahify", :options=>{:fields=>%w{a b}}}}
      Blahify.expects(:render).with('dude', :fields=>%w{a b})
      Hirb::View.output_value('dude')
    end
  end
end
