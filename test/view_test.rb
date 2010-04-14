require File.join(File.dirname(__FILE__), 'test_helper')

context "View" do
  def formatter_config
    View.formatter.config
  end
  
  test "page_output pages when view is enabled" do
    Hirb.enable
    View.pager.stubs(:activated_by?).returns(true)
    View.pager.expects(:page)
    View.page_output('blah').should == true
    Hirb.disable
  end

  test "page_output doesn't page when view is disabled" do
    Hirb.enable
    Hirb.disable
    View.pager.stubs(:activated_by?).returns(true)
    View.pager.expects(:page).never
    View.page_output('blah').should == false
  end

  test "view_output catches unexpected errors and prints them" do
    reset_config
    Hirb.enable
    View.expects(:render_output).raises('blah')
    capture_stderr { View.view_output([1,2,3]) }.should =~ /Hirb Error: blah/
    Hirb.disable
  end

  context "enable" do
    before { reset_config }
    after { Hirb.disable }
    test "redefines irb output_value" do
      View.expects(:render_output).once
      Hirb.enable
      context_stub = stub(:last_value=>'')
      ::IRB::Irb.new(context_stub).output_value
    end

    test "is enabled?" do
      Hirb.enable
      View.enabled?.should == true
    end

    def output_class_config(klass)
      { :output=>{klass=>{:class=>:auto_table}} }
    end

    test "sets formatter config" do
      class_hash = {"Something::Base"=>{:class=>"BlahBlah"}}
      Hirb.enable :output=>class_hash
      View.formatter_config['Something::Base'].should == class_hash['Something::Base']
    end

    test "when called multiple times merges configs" do
      Hirb.config = nil
      # default config + config_file
      Hirb.expects(:read_config_file).returns(output_class_config('Regexp'))
      Hirb.enable output_class_config('String')

      # add config file and explicit config
      [{:config_file=>'ok'}, output_class_config('Struct')].each do |config|
        Hirb.expects(:read_config_file).times(2).returns(
          output_class_config('ActiveRecord::Base'), output_class_config('Array'))
        Hirb.enable config
      end

      Hirb.config_files.include?('ok').should == true
      output_keys = %w{ActiveRecord::Base Array Regexp String Struct}
      Hirb::View.config[:output].keys.sort.should == output_keys
    end

    test "when called multiple times without config doesn't affect config" do
      Hirb.enable
      old_config = Hirb::View.config
      Hirb.expects(:read_config_file).never
      Hirb::View.expects(:load_config).never
      Hirb.enable
      Hirb::View.config.should == old_config
    end

    test "works without irb" do
      Object.stubs(:const_defined?).with(:IRB).returns(false)
      Hirb.enable
      formatter_config.size.should.be > 0
    end

    test "with config_file option adds to config_file" do
      Hirb.enable :config_file=> 'test_file'
      Hirb.config_files.include?('test_file').should == true
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
    before { View.pager = nil; reset_config; Hirb.enable }
    after { Hirb.disable}
    test "changes width and height with stty" do
      Util.expects(:command_exists?).with('stty').returns(true)
      ENV['COLUMNS'] = ENV['LINES'] = nil # bypasses env usage
      View.resize
      pager.width.should.not == 10
      pager.height.should.not == 10
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
      pager.width.is_a?(Integer).should == true
      pager.height.is_a?(Integer).should == true
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
    View.enabled?.should == false
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
