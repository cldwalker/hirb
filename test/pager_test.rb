require File.join(File.dirname(__FILE__), 'test_helper')

describe "Pager" do
  def pager; View.pager; end

  def create_pageable_string(inspect_mode=false, size={})
    size = {:width=>pager.width, :height=>pager.height}.merge(size)
    seed = inspect_mode ? "a" : "a\n"
    if inspect_mode
      seed * (size[:width] * size[:height] + 1)
    else
      seed * (size[:height] + 1)
    end
  end

  it "command_pager sets pager_command when command exists" do
    Util.expects(:command_exists?).returns(true)
    Pager.expects(:basic_pager)
    Pager.command_pager 'blah', :pager_command=>'less'
  end

  it "command_pager doesn't set pager_command when command doesn't exist" do
    Util.expects(:command_exists?).returns(false)
    Pager.expects(:basic_pager).never
    Pager.command_pager 'blah', :pager_command=>'moreless'
  end

  describe "default_pager" do
    before_all { reset_config; Hirb.enable :pager=>true }
    before { View.pager = nil; Pager.stubs(:pager_command).returns(nil) }

    it "pages once in normal mode" do
      $stdin.expects(:gets).returns("\n")
      output = capture_stdout { pager.page(create_pageable_string, false) }
      output.include?('quit').should == true
      output.include?('finished').should == true
    end

    it "doesn't page in normal mode" do
      $stdin.expects(:gets).never
      output = capture_stdout { pager.page("a\n", false) }
      output.include?("a\n=== Pager finished. ===\n").should == true
    end

    it "pages once in inspect mode" do
      $stdin.expects(:gets).returns("\n")
      output = capture_stdout { pager.page(create_pageable_string(true), true) }
      output.include?('quit').should == true
      output.include?('finished').should == true
    end

    it "doesn't page in inspect mode" do
      $stdin.expects(:gets).never
      output = capture_stdout { pager.page("a", true) }
      output.include?("a\n=== Pager finished. ===\n").should == true
    end
    after_all { Hirb.disable }
  end

  describe "pager" do
    before_all { reset_config; Hirb.enable }
    before { View.pager = nil; View.formatter = nil }

    def irb_eval(string)
      context_stub = stub(:last_value=>string)
      ::IRB::Irb.new(context_stub).output_value
    end

    # this mode is called within @irb.output_value
    describe "in inspect_mode" do
      it "activates when output is wide enough" do
        output = create_pageable_string(true)
        pager.expects(:page).with(output.inspect, true)
        View.expects(:render_output).returns(false)
        irb_eval output
      end

      it "doesn't activate when output isn't wide enough" do
        pager.expects(:page).never
        View.expects(:render_output).returns(false)
        irb_eval("a")
      end

      it "activates with an explicit width" do
        View.config[:width] = 10
        output = create_pageable_string true, :width=>10
        pager.expects(:page).with(output.inspect, true)
        View.expects(:render_output).returns(false)
        irb_eval output
      end

      it "activates default_pager when pager command is invalid" do
        Pager.expects(:pager_command).returns(nil)
        output = create_pageable_string(true)
        Pager.expects(:default_pager).with(output.inspect, anything)
        View.expects(:render_output).returns(false)
        capture_stdout { irb_eval output }
      end
    end

    # this mode is called within View.render_output
    describe "in normal mode" do
      it "activates when output is long enough" do
        output = create_pageable_string
        View.formatter.expects(:format_output).returns(output)
        pager.expects(:page).with(output, false)
        irb_eval(output)
      end

      it "doesn't activate when output isn't long enough" do
        output = "a\n"
        View.formatter.expects(:format_output).returns(output)
        pager.expects(:page).never
        capture_stdout { irb_eval(output) }
      end

      it "activates with an explicit height" do
        View.config[:height] = 100
        output = create_pageable_string false, :height=>100
        View.formatter.expects(:format_output).returns(output)
        pager.expects(:page).with(output, false)
        irb_eval(output)
      end

      it "activates default_pager when pager_command is invalid" do
        Pager.expects(:pager_command).returns(nil)
        output = create_pageable_string
        Pager.expects(:default_pager).with(output, anything)
        View.formatter.expects(:format_output).returns(output)
        capture_stdout { irb_eval output }
      end
    end

    it "activates pager_command with valid pager_command option" do
      View.config[:pager_command] = "less"
      View.expects(:render_output).returns(false)
      Util.expects(:command_exists?).returns(true)
      Pager.expects(:command_pager)
      irb_eval create_pageable_string(true)
      View.config[:pager_command] = nil
    end

    it "activates pager_command with pager_command option that has command options" do
      View.config[:pager_command] = "less -r"
      View.expects(:render_output).returns(false)
      Util.expects(:command_exists?).with('less').returns(true)
      Pager.expects(:command_pager)
      irb_eval create_pageable_string(true)
      View.config[:pager_command] = nil
    end

    it "doesn't activate pager_command with invalid pager_command option" do
      View.config[:pager_command] = "moreless"
      View.expects(:render_output).returns(false)
      Util.expects(:command_exists?).returns(false)
      Pager.expects(:default_pager)
      irb_eval create_pageable_string(true)
      View.config[:pager_command] = nil
    end
  end
  after_all { Hirb.disable }
end