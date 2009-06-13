require File.join(File.dirname(__FILE__), 'test_helper')

class Hirb::PagerTest < Test::Unit::TestCase
  # "default irb" refers to execution within @irb.output_value after Hirb::View.render_output
  context "pager" do
    before(:each) { Hirb::View.config = {}}
    after(:each) { Hirb::View.disable }

    def irb_eval(string)
      context_stub = stub(:last_value=>string)
      ::IRB::Irb.new(context_stub).output_value
    end

    def create_pageable_string(width_mode=false, size={})
      size.merge! :width=>Hirb::View.pager.width, :height=>Hirb::View.pager.height
      seed = width_mode ? "a" : "a\n"
      if width_mode
        seed * (size[:width] * size[:height] + 1)
      else
        seed * (size[:height] + 1)
      end
    end

    test "not set by default" do
      Hirb::View.enable
      Hirb::View.config[:pager].should be(false)
    end

    test "activates within default irb when output is wide enough" do
      Hirb::View.enable {|c| c.pager = true}
      input = create_pageable_string(true)
      Hirb::View.pager.expects(:page).with(input.inspect, true)
      Hirb::View.expects(:render_output).returns(false)
      irb_eval input
    end

    test "doesn't activate within default irb when output isn't wide enough" do
      Hirb::View.enable {|c| c.pager = true}
      Hirb::View.pager.expects(:page).never
      Hirb::View.expects(:render_output).returns(false)
      irb_eval("a")
    end

    test "activates within default irb with an explicit width" do
      Hirb::View.enable {|c| c.pager = true; c.width = 10}
      input = create_pageable_string true, :width=>10
      Hirb::View.pager.expects(:page).with(input.inspect, true)
      Hirb::View.expects(:render_output).returns(false)
      irb_eval input
    end

    test "renders default within default irb when pager binary is invalid" do
      Hirb::View.enable {|c| c.pager = true}
      Hirb::Pager.expects(:pager_binary).returns(nil)
      Hirb::View.expects(:render_output).returns(false)
      Hirb::View.pager.expects(:page).never
      irb_eval create_pageable_string(true)
    end


    test "activates within render_output when output is long enough" do
      Hirb::View.enable {|c| c.pager = true}
      input = create_pageable_string
      Hirb::View.expects(:format_output).returns(input)
      Hirb::View.pager.expects(:page).with(input, false)
      irb_eval(input)
    end

    test "doesn't activate within render_output when output isn't long enough" do
      Hirb::View.enable {|c| c.pager = true}
      input = "a\n"
      Hirb::View.expects(:format_output).returns(input)
      Hirb::View.pager.expects(:page).never
      capture_stdout { irb_eval(input) }
    end

    test "activates within render_output with an explicit height" do
      Hirb::View.enable {|c| c.pager = true; c.height = 100 }
      input = create_pageable_string false, :height=>100
      Hirb::View.expects(:format_output).returns(input)
      Hirb::View.pager.expects(:page).with(input, false)
      irb_eval(input)
    end

    test "renders default within render_output when pager_binary is invalid" do
      Hirb::View.enable {|c| c.pager = true}
      Hirb::Pager.expects(:pager_binary).returns(nil)
      input = create_pageable_string
      Hirb::View.expects(:format_output).returns(input)
      Hirb::View.pager.expects(:page).never
      capture_stdout { irb_eval input }
    end

    test "state is toggled by toggle_pager" do
      Hirb::View.enable {|c| c.pager = true}
      Hirb::View.toggle_pager
      Hirb::View.config[:pager].should == false
    end

    test "when resized changes width and height" do
      Hirb::View.enable {|c| c.pager = true}
      ENV['COLUMNS'] = ENV['LINES'] = '10' # simulates resizing
      Hirb::View.resize
      Hirb::View.pager.width.should == 10
      Hirb::View.pager.height.should == 10
    end
  end
end
