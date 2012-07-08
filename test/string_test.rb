require File.join(File.dirname(__FILE__), 'test_helper')

describe "Hirb::String" do

  describe "size" do
    it "should return the size of the string" do
      Hirb::String.size("cats").should == 4
    end

    describe "with a colorized string" do
      it "should return the size of the string without the color codes" do
        Hirb::String.size("\e[31mcats\e[0m").should == 4
      end
    end
  end

  describe "ljust" do
    it "should return a properly padded string" do
      Hirb::String.ljust("cats", 6).should == "cats  "
    end

    describe "with a colorized string" do
      it "should return a properly padded string" do
        Hirb::String.ljust("\e[31mcats\e[0m", 6).should == "\e[31mcats\e[0m  "
      end
    end
  end

  describe "rjust" do
    it "should return a properly padded string" do
      Hirb::String.rjust("cats", 6).should == "  cats"
    end

    describe "with a colorized string" do
      it "should return a properly padded string" do
        Hirb::String.rjust("\e[31mcats\e[0m", 6).should == "  \e[31mcats\e[0m"
      end
    end
  end

  describe "slice" do
    it "should return a properly sliced string" do
      Hirb::String.slice("kittycats", 0, 5).should == "kitty"
    end

    describe "with a colorized string" do
      it "should return a properly sliced string" do
        Hirb::String.slice("\e[31mk\e[30mi\e[29mttyc\e[28mats\e[0m", 0, 5).should == "\e[31mk\e[30mi\e[29mtty\e[28m\e[0m"
      end
    end
  end

end