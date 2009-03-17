require File.join(File.dirname(__FILE__), 'test_helper')

class Hirb::Helpers::TreeTest < Test::Unit::TestCase
  def tree(*args)
    Hirb::Helpers::Tree.render(*args)
  end
  
  test "filesystem tree renders" do
    expected_tree = <<-TREE.unindent
    0.0
    |-- 1.1
    |   |-- 2.2
    |   `-- 3.2
    `-- 4.1
    TREE
    tree([[0, "0.0"], [1, "1.1"], [2, "2.2"], [2, "3.2"], [1, "4.1"]], :type=>:filesystem).should == expected_tree
  end
  
  test "filesystem tree with multiple children per level renders" do
    expected_tree = <<-TREE.unindent
    0.0
    |-- 1.1
    |   |-- 2.2
    |   |   `-- 3.3
    |   `-- 4.2
    |       `-- 5.3
    `-- 6.1
    TREE
    tree([[0,'0.0'], [1,'1.1'], [2,'2.2'],[3,'3.3'],[2,'4.2'],[3,'5.3'],[1,'6.1']], :type=>:filesystem).should == expected_tree
  end
  
  test "basic tree with hash nodes renders" do
    expected_tree = <<-TREE.gsub(/^    /, '').chomp
    0.0
        1.1
            2.2
            3.2
        4.1
    TREE
    tree([{:level=>0, :value=>'0.0'}, {:level=>1, :value=>'1.1'}, {:level=>2, :value=>'2.2'},{:level=>2, :value=>'3.2'},
       {:level=>1, :value=>'4.1'}]).should == expected_tree
  end
  
  test "basic tree renders" do
    expected_tree = <<-TREE.gsub(/^    /, '').chomp
    0.0
        1.1
            2.2
            3.2
        4.1
    TREE
    tree([[0, "0.0"], [1, "1.1"], [2, "2.2"], [2, "3.2"], [1, "4.1"]]).should == expected_tree
  end
  
end