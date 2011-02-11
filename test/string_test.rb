# coding: utf-8
require File.join(File.dirname(__FILE__), 'test_helper')

describe "String" do

  describe ".display_width returns correct width" do
    it "given non-unicode string" do
      Hirb::String.display_width("Hello, world.").should == 13
    end
    it "given unicode string" do
      Hirb::String.display_width("鄉民您好").should == 8
      Hirb::String.display_width("こんにちは").should == 10
      Hirb::String.display_width("中英夾雜yoo").should == 11
    end
  end

  describe ".ljust returns justified string" do
    it "given non-unicode string" do
      Hirb::String.ljust("Hello, world.", 15).should == "Hello, world.  "
      Hirb::String.ljust("Hello, world.", 5).should == "Hello, world."
    end
    it "given unicode string" do
      Hirb::String.ljust("還我牛", 9).should == "還我牛   "
      Hirb::String.ljust("維大利", 5).should == "維大利"
    end
  end

  describe ".rjust returns justified string" do
    it "given non-unicode string" do
      Hirb::String.rjust("Hello, world.", 15).should == "  Hello, world."
      Hirb::String.rjust("Hello, world.", 1).should == "Hello, world."
    end
    it "given unicode string" do
      Hirb::String.rjust("恭喜發財", 13).should == "     恭喜發財"
      Hirb::String.rjust("紅包拿來", 1).should == "紅包拿來"
    end
  end

  describe ".truncate returns truncated string" do
    it "given non-unicode string" do
      Hirb::String.truncate("Hello, world.", 10).should == "Hello, wor"
    end
    it "given unicode string that could exactly match the length" do
      Hirb::String.truncate("三民主義五權憲法", 8).should == "三民主義"
    end
    it "given unicode string that couldn't exactly match the length" do
      Hirb::String.truncate("六合彩大樂透", 5).should == "六合"
    end
  end

  describe ".split_at_display_width returns 2 strings splitted at specified width" do
    it "given non-unicode string" do
      Hirb::String.split_at_display_width("Hello, world.", 5).should == ["Hello", ", world."]
      Hirb::String.split_at_display_width("Hello, world.", 100).should == ["Hello, world.", ""]
    end
    it "given unicode string that could exactly match the length" do
      Hirb::String.split_at_display_width("頭獎上看六億", 10).should == ["頭獎上看六", "億"]
      Hirb::String.split_at_display_width("頭獎上看六億", 100).should == ["頭獎上看六億", ""]
    end
    it "given unicode string that couldn't exactly match the length" do
      Hirb::String.split_at_display_width("可是你不會中獎", 7).should == ["可是你", "不會中獎"]
      Hirb::String.split_at_display_width("可是你不會中獎", 100).should == ["可是你不會中獎", ""]
    end
  end

end
