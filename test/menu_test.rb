require File.join(File.dirname(__FILE__), 'test_helper')

class Hirb::MenuTest < Test::Unit::TestCase
  def menu(*args, &block)
    # testing via menu's main use case (through console) instead of Hirb::Menu.render
    @console ||= Object.new.extend(Hirb::Console)
    @console.menu(*args, &block)
  end

  def basic_menu(*args, &block)
    menu_input('1')
    capture_stdout { menu(*args, &block).should == [1] }
  end

  def menu_input(input='')
    $stdin.expects(:gets).returns(input)
  end

  context "menu" do
    test "by default renders table menu" do
      expected_menu = <<-MENU.unindent
      +--------+-------+
      | number | value |
      +--------+-------+
      | 1      | 1     |
      | 2      | 2     |
      | 3      | 3     |
      +--------+-------+
      3 rows in set
      MENU
      basic_menu([1,2,3]).include?(expected_menu).should == true
    end

    test "with block renders" do
      menu_input "1,2"
      expected_result = [1,2]
      capture_stdout { 
        menu([1,2,3]) {|e| e.should == expected_result }.should == expected_result
      }
    end

    test "with block and no chosen doesn't call block" do
      menu_input ""
      block = lambda {|e| }
      block.expects(:call).never
      capture_stdout {
        menu([1,2,3], &block).should == []
      }
    end

    test "with valid helper_class option renders" do
      Hirb::Helpers::Table.expects(:render)
      basic_menu [1,2,3], :helper_class=>"Hirb::Helpers::Table"
    end

    test "with invalid helper_class option renders default menu" do
      expected_menu = <<-MENU.unindent
      1: 1
      2: 2
      3: 3
      MENU
      basic_menu([1,2,3], :helper_class=>"SomeHelper").include?(expected_menu).should == true
    end

    test "with false helper_class option renders default menu" do
      expected_menu = <<-MENU.unindent
      1: 1
      2: 2
      3: 3
      MENU
      basic_menu([1,2,3], :helper_class=>false).include?(expected_menu).should == true
    end

    test "prints prompt option" do
      prompt = "Input or else ..."
      basic_menu([1,2,3], :prompt=>prompt).include?(prompt).should == true
    end

    test "converts non-array inputs to array" do
      Hirb::Helpers::AutoTable.expects(:render).with([1], anything)
      basic_menu 1
    end

    test "with false ask option returns one choice without asking" do
      $stdin.expects(:gets).never
      menu([1], :ask=>false).should == [1]
    end

    test "with validate_one option returns chosen one" do
      menu_input '2'
      capture_stdout { menu([1,2,3], :validate_one=> true).should == 2 }
    end
  end
end