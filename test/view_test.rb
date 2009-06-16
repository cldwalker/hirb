require File.join(File.dirname(__FILE__), 'test_helper')

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

  test "page_output pages when view is enabled" do
    Hirb::View.enable
    Hirb::View.pager.stubs(:activated_by?).returns(true)
    Hirb::View.pager.expects(:page)
    Hirb::View.page_output('blah').should be(true)
    Hirb::View.disable
  end
  
  test "page_output doesn't page when view is disabled" do
    Hirb::View.enable
    Hirb::View.disable
    Hirb::View.pager.stubs(:activated_by?).returns(true)
    Hirb::View.pager.expects(:page).never
    Hirb::View.page_output('blah').should be(false)
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

    test "is enabled?" do
      Hirb::View.enable
      assert Hirb::View.enabled?
    end

    test "works without irb" do
      Object.stubs(:const_defined?).with(:IRB).returns(false)
      Hirb::View.enable
      assert output_config.size > 0
    end

    test "with config_file option sets config_file" do
      Hirb.config_file.should_not == 'test_file'
      Hirb::View.enable :config_file=> 'test_file'
      Hirb.config_file.should == 'test_file'
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

  test "disable works without irb defined" do
    Object.stubs(:const_defined?).with(:IRB).returns(false)
    Hirb::View.enable
    Hirb::View.disable
    Hirb::View.enabled?.should be(false)
  end

  test "capture_and_render" do
    string = 'no waaaay'
    Hirb::View.render_method.expects(:call).with(string)
    Hirb::View.capture_and_render { print string }
  end

  context "parse_console_input" do
    before(:each) { Hirb::View.config = nil }
    test "config is set if it wasn't before" do
      Hirb::View.config = nil
      Hirb::View.expects(:render_output)
      Hirb::View.console_render_output('blah')
      Hirb::View.config.is_a?(Hash).should == true
    end

    test "convert symbol to :class option" do
      Hirb::View.expects(:render_output).with('blah', :class=>"Hirb::Helpers::Table", :options=>{})
      Hirb::View.console_render_output('blah', :table)
    end

    test "passes all options except for formatter options into :options" do
      options = {:class=>'blah', :method=>'blah', :output_method=>'blah', :blah=>'blah'}
      expected_options = {:class=>'blah', :method=>'blah', :output_method=>'blah', :options=>{:blah=>'blah'}}
      Hirb::View.expects(:render_output).with('blah', expected_options)
      Hirb::View.console_render_output('blah', options)
    end
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
    
    test "formats with output_method option as method" do
      set_config 'String'=>{:class=>"Blahify"}
      Hirb::View.render_method.expects(:call).with('d,u,d')
      Hirb::View.render_output('dude', :class=>"Commify", :output_method=>:chop)
    end

    test "formats with output_method option as proc" do
      set_config 'String'=>{:class=>"Blahify"}
      Hirb::View.render_method.expects(:call).with('d,u,d')
      Hirb::View.render_output('dude', :class=>"Commify", :output_method=>lambda {|e| e.chop})
    end

    test "formats output array with output_method option" do
      set_config 'String'=>{:class=>"Blahify"}
      Hirb::View.render_method.expects(:call).with("d,u,d\nm,a")
      Hirb::View.render_output(['dude', 'man'], :class=>"Commify", :output_method=>:chop)
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
