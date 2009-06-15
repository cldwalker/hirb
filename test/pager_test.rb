require File.join(File.dirname(__FILE__), 'test_helper')

class Hirb::PagerTest < Test::Unit::TestCase
  def create_pageable_string(inspect_mode=false, size={})
    size = {:width=>Hirb::View.pager.width, :height=>Hirb::View.pager.height}.merge(size)
    seed = inspect_mode ? "a" : "a\n"
    if inspect_mode
      seed * (size[:width] * size[:height] + 1)
    else
      seed * (size[:height] + 1)
    end
  end

  test "command_pager sets pager_command when command exists" do
    Hirb::Util.expects(:command_exists?).returns(true)
    Hirb::Pager.expects(:basic_pager)
    Hirb::Pager.command_pager 'blah', :pager_command=>'less'
  end

  test "command_pager doesn't set pager_command when command doesn't exist" do
    Hirb::Util.expects(:command_exists?).returns(false)
    Hirb::Pager.expects(:basic_pager).never
    Hirb::Pager.command_pager 'blah', :pager_command=>'moreless'
  end

  context "default_pager" do
    before(:all) { Hirb::View.config = {}; Hirb::View.enable {|c| c.pager = true}}
    before(:each) { Hirb::View.pager = nil; Hirb::Pager.stubs(:pager_command).returns(nil) }
    after(:all) { Hirb::View.disable }

    test "pages once in normal mode" do
      $stdin.expects(:gets).returns("\n")
      output = capture_stdout { Hirb::View.pager.page(create_pageable_string, false) }
      output.include?('quit').should be(true)
      output.include?('finished').should be(true)
    end

    test "doesn't page in normal mode" do
      $stdin.expects(:gets).never
      output = capture_stdout { Hirb::View.pager.page("a\n", false) }
      output.include?("a\n=== Pager finished. ===\n").should be(true)
    end

    test "pages once in inspect mode" do
      $stdin.expects(:gets).returns("\n")
      output = capture_stdout { Hirb::View.pager.page(create_pageable_string(true), true) }
      output.include?('quit').should be(true)
      output.include?('finished').should be(true)
    end

    test "doesn't page in inspect mode" do
      $stdin.expects(:gets).never
      output = capture_stdout { Hirb::View.pager.page("a", true) }
      output.include?("a\n=== Pager finished. ===\n").should be(true)
    end
  end

  context "pager" do
    before(:all) { Hirb::View.config = {}; Hirb::View.enable }
    before(:each) { Hirb::View.pager = nil }
    after(:all) { Hirb::View.disable }

    def irb_eval(string)
      context_stub = stub(:last_value=>string)
      ::IRB::Irb.new(context_stub).output_value
    end

    # this mode is called within @irb.output_value
    context "in inspect_mode" do
      test "activates when output is wide enough" do
        output = create_pageable_string(true)
        Hirb::View.pager.expects(:page).with(output.inspect, true)
        Hirb::View.expects(:render_output).returns(false)
        irb_eval output
      end

      test "doesn't activate when output isn't wide enough" do
        Hirb::View.pager.expects(:page).never
        Hirb::View.expects(:render_output).returns(false)
        irb_eval("a")
      end

      test "activates with an explicit width" do
        Hirb::View.config[:width] = 10
        output = create_pageable_string true, :width=>10
        Hirb::View.pager.expects(:page).with(output.inspect, true)
        Hirb::View.expects(:render_output).returns(false)
        irb_eval output
      end

      test "activates default_pager when pager command is invalid" do
        Hirb::Pager.expects(:pager_command).returns(nil)
        output = create_pageable_string(true)
        Hirb::Pager.expects(:default_pager).with(output.inspect, anything)
        Hirb::View.expects(:render_output).returns(false)
        capture_stdout { irb_eval output }
      end
    end

    # this mode is called within Hirb::View.render_output
    context "in normal mode" do
      test "activates when output is long enough" do
        output = create_pageable_string
        Hirb::View.expects(:format_output).returns(output)
        Hirb::View.pager.expects(:page).with(output, false)
        irb_eval(output)
      end

      test "doesn't activate when output isn't long enough" do
        output = "a\n"
        Hirb::View.expects(:format_output).returns(output)
        Hirb::View.pager.expects(:page).never
        capture_stdout { irb_eval(output) }
      end

      test "activates with an explicit height" do
        Hirb::View.config[:height] = 100
        output = create_pageable_string false, :height=>100
        Hirb::View.expects(:format_output).returns(output)
        Hirb::View.pager.expects(:page).with(output, false)
        irb_eval(output)
      end

      test "activates default_pager when pager_command is invalid" do
        Hirb::Pager.expects(:pager_command).returns(nil)
        output = create_pageable_string
        Hirb::Pager.expects(:default_pager).with(output, anything)
        Hirb::View.expects(:format_output).returns(output)
        capture_stdout { irb_eval output }
      end
    end

    test "state is toggled by toggle_pager" do
      Hirb::View.toggle_pager
      Hirb::View.config[:pager].should == false
    end

    test "when resized changes width and height with stty" do
      Hirb::Util.expects(:command_exists?).with('stty').returns(true)
      ENV['COLUMNS'] = ENV['LINES'] = nil # bypasses env usage
      Hirb::View.resize
      Hirb::View.pager.width.should_not == 10
      Hirb::View.pager.height.should_not == 10
      reset_terminal_size
    end

    test "when resized changes width and height with ENV" do
      ENV['COLUMNS'] = ENV['LINES'] = '10' # simulates resizing
      Hirb::View.resize
      Hirb::View.pager.width.should == 10
      Hirb::View.pager.height.should == 10
    end

    test "when resized and no environment or stty still has valid width and height" do
      Hirb::View.config[:width] = Hirb::View.config[:height] = nil
      Hirb::Util.expects(:command_exists?).with('stty').returns(false)
      ENV['COLUMNS'] = ENV['LINES'] = nil
      Hirb::View.resize
      Hirb::View.pager.width.is_a?(Integer).should be(true)
      Hirb::View.pager.height.is_a?(Integer).should be(true)
      reset_terminal_size
    end

    test "activates pager_command with valid pager_command option" do
      Hirb::View.config[:pager_command] = "less"
      Hirb::View.expects(:render_output).returns(false)
      Hirb::Util.expects(:command_exists?).returns(true)
      Hirb::Pager.expects(:command_pager)
      irb_eval create_pageable_string(true)
      Hirb::View.config[:pager_command] = nil
    end

    test "doesn't activate pager_command with invalid pager_command option" do
      Hirb::View.config[:pager_command] = "moreless"
      Hirb::View.expects(:render_output).returns(false)
      Hirb::Util.expects(:command_exists?).returns(false)
      Hirb::Pager.expects(:default_pager)
      irb_eval create_pageable_string(true)
      Hirb::View.config[:pager_command] = nil
    end
  end
end
