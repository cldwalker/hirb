require File.join(File.dirname(__FILE__), 'test_helper')

class Hirb::ViewTest < Test::Unit::TestCase
  def formatter_config
    Hirb::View.formatter.config
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
    before(:each) { reset_config }
    after(:each) { Hirb::View.disable }
    test "redefines irb output_value" do
      Hirb::View.expects(:render_output).once
      Hirb::View.enable
      context_stub = stub(:last_value=>'')
      ::IRB::Irb.new(context_stub).output_value
    end
    test "is enabled?" do
      Hirb::View.enable
      assert Hirb::View.enabled?
    end

    test "works without irb" do
      Object.stubs(:const_defined?).with(:IRB).returns(false)
      Hirb::View.enable
      assert formatter_config.size > 0
    end

    test "with config_file option sets config_file" do
      Hirb.config_file.should_not == 'test_file'
      Hirb::View.enable :config_file=> 'test_file'
      Hirb.config_file.should == 'test_file'
    end
  end

  test "reload_config resets config to detect new Hirb::Views" do
    Hirb::View.load_config
    formatter_config.keys.include?('Zzz').should be(false)
    eval "module ::Hirb::Views::Zzz; def self.render; end; end"
    Hirb::View.reload_config
    formatter_config.keys.include?('Zzz').should be(true)
  end
  
  test "reload_config picks up local changes" do
    Hirb::View.load_config
    formatter_config.keys.include?('Dooda').should be(false)
    Hirb::View.formatter.config.merge!('Dooda'=>{:class=>"DoodaView"})
    Hirb::View.reload_config
    formatter_config['Dooda'].should == {:class=>"DoodaView"}
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
end
