require File.join(File.dirname(__FILE__), 'test_helper')

class Hirb::FormatterTest < Test::Unit::TestCase
  def set_formatter_config(value)
    Hirb::View.formatter.config = value
    Hirb::View.formatter.reset_cached_config
  end  

  context "formatter" do
    before(:each) { @formatter = Hirb::Formatter.new }

    test "output_class_options merges ancestor options" do
      @formatter.config = {"String"=>{:args=>[1,2]}, "Object"=>{:method=>:object_output, :ancestor=>true}, "Kernel"=>{:method=>:default_output}}
      expected_result = {:method=>:object_output, :args=>[1, 2], :ancestor=>true}
      @formatter.output_class_options(String).should == expected_result
    end

    test "output_class_options doesn't ancestor options" do
      @formatter.config = {"String"=>{:args=>[1,2]}, "Object"=>{:method=>:object_output}, "Kernel"=>{:method=>:default_output}}
      expected_result = {:args=>[1, 2]}
      @formatter.output_class_options(String).should == expected_result
    end

    test "output_class_options returns hash when nothing found" do
      @formatter.output_class_options(String).should == {}
    end
  end

  context "enable" do
    before(:each) { Hirb::View.formatter = nil; reset_config }
    after(:each) { Hirb::View.disable }

    def formatter_config
      Hirb::View.formatter.config
    end
    
    test "sets default config" do
      eval "module ::Hirb::Views::Something_Base; def self.render; end; end"
      Hirb::View.enable
      formatter_config["Something::Base"].should == {:class=>"Hirb::Views::Something_Base"}
    end
  
    test "sets default config with default_options" do
      eval "module ::Hirb::Views::Blah; def self.render; end; def self.default_options; {:ancestor=>true}; end; end"
      Hirb::View.enable
      formatter_config["Blah"].should == {:class=>"Hirb::Views::Blah", :ancestor=>true}
    end
  
    test "with block sets config" do
      class_hash = {"Something::Base"=>{:class=>"BlahBlah"}}
      Hirb::View.enable {|c| c.output = class_hash }
      formatter_config['Something::Base'].should == class_hash['Something::Base']
    end
  end

  context "render_output" do
    def render_output(*args, &block); Hirb::View.render_output(*args, &block); end
    def render_method(*args); Hirb::View.render_method(*args); end

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
      set_formatter_config "String"=>{:method=>:commify}
      render_method.expects(:call).with('d,u,d,e')
      render_output('dude')
    end
    
    test "formats with config class option" do
      set_formatter_config "String"=>{:class=>"Commify"}
      render_method.expects(:call).with('d,u,d,e')
      render_output('dude')
    end
    
    test "formats with output array" do
      set_formatter_config "String"=>{:class=>"Commify"}
      render_method.expects(:call).with('d,u,d,e')
      render_output(['dude'])
    end
    
    test "formats with config options option" do
      eval "module ::Blahify; def self.render(*args); end; end"
      set_formatter_config "String"=>{:class=>"Blahify", :options=>{:fields=>%w{a b}}}
      Blahify.expects(:render).with('dude', :fields=>%w{a b})
      render_output('dude')
    end
    
    test "doesn't format and returns false when no format method found" do
      Hirb::View.load_config
      render_method.expects(:call).never
      render_output(Date.today).should == false
    end
    
    test "formats with explicit class option" do
      set_formatter_config 'String'=>{:class=>"Blahify"}
      render_method.expects(:call).with('d,u,d,e')
      render_output('dude', :class=>"Commify")
    end
    
    test "formats with output_method option as method" do
      set_formatter_config 'String'=>{:class=>"Blahify"}
      render_method.expects(:call).with('d,u,d')
      render_output('dude', :class=>"Commify", :output_method=>:chop)
    end

    test "formats with output_method option as proc" do
      set_formatter_config 'String'=>{:class=>"Blahify"}
      render_method.expects(:call).with('d,u,d')
      render_output('dude', :class=>"Commify", :output_method=>lambda {|e| e.chop})
    end

    test "formats output array with output_method option" do
      set_formatter_config 'String'=>{:class=>"Blahify"}
      render_method.expects(:call).with("d,u,d\nm,a")
      render_output(['dude', 'man'], :class=>"Commify", :output_method=>:chop)
    end

    test "formats with block" do
      Hirb::View.load_config
      render_method.expects(:call).with('=dude=')
      render_output('dude') {|output|
        "=#{output}="
      }
    end
    
    test "console_render_output merge options option" do
      set_formatter_config "String"=>{:class=>"Commify", :options=>{:fields=>%w{f1 f2}}}
      Commify.expects(:render).with('dude', :max_width=>10, :fields=>%w{f1 f2})
      render_output('dude', :options=>{:max_width=>10})
    end
  end
end
