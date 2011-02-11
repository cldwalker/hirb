require File.join(File.dirname(__FILE__), 'test_helper')

describe "String" do

  describe ".display_width returns correct width" do
    it "given non-unicode string" do
      Hirb::String.display_width("Hello, world.").should == 13
    end
  end

  describe ".ljust returns justified string" do
    it "given non-unicode string" do
      Hirb::String.ljust("Hello, world.", 15).should == "Hello, world.  "
    end
  end

  describe ".rjust returns justified string" do
    it "given non-unicode string" do
      Hirb::String.rjust("Hello, world.", 15).should == "  Hello, world."
    end
  end

  describe ".rjust returns truncated string" do
    it "given non-unicode string" do
      Hirb::String.truncate("Hello, world.", 10).should == "Hello, wor"
    end
  end

  describe ".split_at_display_width returns 2 strings splitted at specified width" do
    it "given non-unicode string" do
      Hirb::String.split_at_display_width("Hello, world.", 5).should == ["Hello", ", world."]
    end
  end

  # it "resize ensures columns total doesn't exceed max width" do
  #   table :field_lengths=>{:f1=>135, :f2=>45, :f3=>4, :f4=>55}, :width=>195
  #   Helpers::Table::Resizer.resize!(@table)
  #   @field_lengths.values.inject {|a,e| a+=e}.should <= @width
  # end

end
