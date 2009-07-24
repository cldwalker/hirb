require File.join(File.dirname(__FILE__), 'test_helper')

module Hirb
  class ViewTest < Test::Unit::TestCase
    def formatter_config
      View.formatter.config
    end
    
    test "page_output pages when view is enabled" do
      Hirb.enable
      View.pager.stubs(:activated_by?).returns(true)
      View.pager.expects(:page)
      View.page_output('blah').should be(true)
      Hirb.disable
    end
    
    test "page_output doesn't page when view is disabled" do
      Hirb.enable
      Hirb.disable
      View.pager.stubs(:activated_by?).returns(true)
      View.pager.expects(:page).never
      View.page_output('blah').should be(false)
    end

    context "enable" do
      before(:each) { reset_config }
      after(:each) { Hirb.disable }
      test "redefines irb output_value" do
        View.expects(:render_output).once
        Hirb.enable
        context_stub = stub(:last_value=>'')
        ::IRB::Irb.new(context_stub).output_value
      end
      test "is enabled?" do
        Hirb.enable
        assert View.enabled?
      end

      test "works without irb" do
        Object.stubs(:const_defined?).with(:IRB).returns(false)
        Hirb.enable
        assert formatter_config.size > 0
      end

      test "with config_file option sets config_file" do
        Hirb.config_file.should_not == 'test_file'
        Hirb.enable :config_file=> 'test_file'
        Hirb.config_file.should == 'test_file'
      end

      test "with output_method option realiases output_method" do
        eval %[module ::Mini; extend self; def output(str); puts(str.inspect); end; end]
        Hirb.enable :output_method=>"Mini.output", :output=>{"Symbol"=>{:output_method=>lambda {|e| e.to_s }}}
        capture_stdout { ::Mini.output(:yoyo) }.should == "yoyo\n"
        capture_stdout { ::Mini.output('blah') }.should == "\"blah\"\n"
      end
    end

    context "resize" do
      def pager; View.pager; end
      before(:each) { View.pager = nil; reset_config; Hirb.enable }
      after(:each) { Hirb.disable}
      test "changes width and height with stty" do
        Util.expects(:command_exists?).with('stty').returns(true)
        ENV['COLUMNS'] = ENV['LINES'] = nil # bypasses env usage
        View.resize
        pager.width.should_not == 10
        pager.height.should_not == 10
        reset_terminal_size
      end

      test "changes width and height with ENV" do
        ENV['COLUMNS'] = ENV['LINES'] = '10' # simulates resizing
        View.resize
        pager.width.should == 10
        pager.height.should == 10
      end

      test "with no environment or stty still has valid width and height" do
        View.config[:width] = View.config[:height] = nil
        Util.expects(:command_exists?).with('stty').returns(false)
        ENV['COLUMNS'] = ENV['LINES'] = nil
        View.resize
        pager.width.is_a?(Integer).should be(true)
        pager.height.is_a?(Integer).should be(true)
        reset_terminal_size
      end
    end

    test "disable points output_value back to original output_value" do
      View.expects(:render_output).never
      Hirb.enable
      Hirb.disable
      context_stub = stub(:last_value=>'')
      ::IRB::Irb.new(context_stub).output_value
    end

    test "disable works without irb defined" do
      Object.stubs(:const_defined?).with(:IRB).returns(false)
      Hirb.enable
      Hirb.disable
      View.enabled?.should be(false)
    end

    test "capture_and_render" do
      string = 'no waaaay'
      View.render_method.expects(:call).with(string)
      View.capture_and_render { print string }
    end
    
    test "state is toggled by toggle_pager" do
      previous_state = View.config[:pager]
      View.toggle_pager
      View.config[:pager].should == !previous_state
    end
    
    test "state is toggled by toggle_formatter" do
      previous_state = View.config[:formatter]
      View.toggle_formatter
      View.config[:formatter].should == !previous_state
    end
  end
end
