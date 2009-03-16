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
  def set_config(value)
    Hirb::View.output_config = value
    Hirb::View.reset_cached_output_config
  end
  
  def output_config
    Hirb::View.config[:output]
  end
  
  test "output_class_options merges ancestor options" do
    set_config "String"=>{:args=>[1,2]}, "Object"=>{:method=>:object_output, :ancestor=>true}, "Kernel"=>{:method=>:default_output}
    expected_result = {:method=>:object_output, :args=>[1, 2], :ancestor=>true}
    Hirb::View.output_class_options(String).should == expected_result
  end
  
  test "output_class_options doesn't ancestor options" do
    set_config "String"=>{:args=>[1,2]}, "Object"=>{:method=>:object_output}, "Kernel"=>{:method=>:default_output}
    expected_result = {:args=>[1, 2]}
    Hirb::View.output_class_options(String).should == expected_result
  end
  
  test "output_class_options returns hash when nothing found" do
    Hirb::View.load_config
    Hirb::View.output_class_options(String).should == {}
  end

  context "enable" do
    before(:each) {Hirb::View.config = {}}
    after(:each) { Hirb::View.disable }
    test "redefines irb output_value" do
      Hirb::View.expects(:render_output).once
      Hirb::View.enable
      context_stub = stub(:last_value=>'')
      ::IRB::Irb.new(context_stub).output_value
    end
  
    test "sets default config" do
      eval "module ::Hirb::Views::Something_Base; def self.render; end; end"
      Hirb::View.enable
      output_config["Something::Base"].should == {:class=>"Hirb::Views::Something_Base"}
    end
  
    test "sets default config with default_options" do
      eval "module ::Hirb::Views::Blah; def self.render; end; def self.default_options; {:ancestor=>true}; end; end"
      Hirb::View.enable
      output_config["Blah"].should == {:class=>"Hirb::Views::Blah", :ancestor=>true}
    end
  
    test "with block sets config" do
      class_hash = {"Something::Base"=>{:class=>"BlahBlah"}}
      Hirb::View.enable {|c| c.output = class_hash }
      output_config['Something::Base'].should == class_hash['Something::Base']
    end
  end

  test "reload_config resets config to detect new Hirb::Views" do
    Hirb::View.load_config
    output_config.keys.include?('Zzz').should be(false)
    eval "module ::Hirb::Views::Zzz; def self.render; end; end"
    Hirb::View.reload_config
    output_config.keys.include?('Zzz').should be(true)
  end
  
  test "reload_config picks up local changes" do
    Hirb::View.load_config
    output_config.keys.include?('Dooda').should be(false)
    Hirb::View.output_config.merge!('Dooda'=>{:class=>"DoodaView"})
    Hirb::View.reload_config
    output_config['Dooda'].should == {:class=>"DoodaView"}
  end
  
  test "disable points output_value back to original output_value" do
    Hirb::View.expects(:render_output).never
    Hirb::View.enable
    Hirb::View.disable
    context_stub = stub(:last_value=>'')
    ::IRB::Irb.new(context_stub).output_value
  end

  context "render_output" do
    before(:all) { 
      eval %[module ::Commify
        def self.render(strings)
          strings = [strings] unless strings.is_a?(Array)
          strings.map {|e| e.split('').join(',')}.join("\n")
        end
      end]
      Hirb::View.enable 
    }
    after(:all) { Hirb::View.disable }
    
    test "formats with config method option" do
      eval "module ::Kernel; def commify(string); string.split('').join(','); end; end"
      set_config "String"=>{:method=>:commify}
      Hirb::View.render_method.expects(:call).with('d,u,d,e')
      Hirb::View.render_output('dude')
    end
    
    test "formats with config class option" do
      set_config "String"=>{:class=>"Commify"}
      Hirb::View.render_method.expects(:call).with('d,u,d,e')
      Hirb::View.render_output('dude')
    end
    
    test "formats with output array" do
      set_config "String"=>{:class=>"Commify"}
      Hirb::View.render_method.expects(:call).with('d,u,d,e')
      Hirb::View.render_output(['dude'])
    end
    
    test "formats with config options option" do
      eval "module ::Blahify; def self.render(*args); end; end"
      set_config "String"=>{:class=>"Blahify", :options=>{:fields=>%w{a b}}}
      Blahify.expects(:render).with('dude', :fields=>%w{a b})
      Hirb::View.render_output('dude')
    end
    
    test "doesn't format and returns false when no format method found" do
      Hirb::View.load_config
      Hirb::View.render_method.expects(:call).never
      Hirb::View.render_output(Date.today).should == false
    end
    
    test "formats with explicit class option" do
      set_config 'String'=>{:class=>"Blahify"}
      Hirb::View.render_method.expects(:call).with('d,u,d,e')
      Hirb::View.render_output('dude', :class=>"Commify")
    end
    
    test "formats with block" do
      Hirb::View.load_config
      Hirb::View.render_method.expects(:call).with('=dude=')
      Hirb::View.render_output('dude') {|output|
        "=#{output}="
      }
    end
    
    test "console_render_output merge options option" do
      set_config "String"=>{:class=>"Commify", :options=>{:fields=>%w{f1 f2}}}
      Commify.expects(:render).with('dude', :max_width=>10, :fields=>%w{f1 f2})
      Hirb::View.render_output('dude', :options=>{:max_width=>10})
    end
  end
end
