require File.join(File.dirname(__FILE__), 'test_helper')

class Hirb::Helpers::TreeTest < Test::Unit::TestCase
  def tree(*args)
    Hirb::Helpers::Tree.render(*args)
  end
  
  context "basic tree" do
    test "with hash nodes renders" do
      expected_tree = <<-TREE.unindent(6)
      0.0
          1.1
              2.2
              3.2
          4.1
      TREE
      tree([{:level=>0, :value=>'0.0'}, {:level=>1, :value=>'1.1'}, {:level=>2, :value=>'2.2'},{:level=>2, :value=>'3.2'},
         {:level=>1, :value=>'4.1'}]).should == expected_tree
    end
  
    test "with array nodes renders" do
      expected_tree = <<-TREE.unindent(6)
      0.0
          1.1
              2.2
              3.2
          4.1
      TREE
      tree([[0, "0.0"], [1, "1.1"], [2, "2.2"], [2, "3.2"], [1, "4.1"]]).should == expected_tree
    end
    
    test "with non-string values renders" do
      expected_tree = <<-TREE.unindent(6)
      0.0
          1.1
              2.2
              3.2
          4.1
      TREE
      tree([[0,0.0],[1,1.1],[2,2.2],[2,3.2],[1,4.1]]).should == expected_tree
    end

    test "with indent option renders" do
      expected_tree = <<-TREE.unindent(6)
      0.0
        1.1
          2.2
          3.2
        4.1
      TREE
      tree([[0, "0.0"], [1, "1.1"], [2, "2.2"], [2, "3.2"], [1, "4.1"]], :indent=>2).should == expected_tree
    end

    test "with limit option renders" do
      expected_tree = <<-TREE.unindent(6)
      0.0
          1.1
          4.1
      TREE
      tree([[0, "0.0"], [1, "1.1"], [2, "2.2"], [2, "3.2"], [1, "4.1"]], :limit=>1).should == expected_tree
    end

    test "with description option renders" do
      expected_tree = <<-TREE.unindent(6)
      0.0
          1.1
              2.2
              3.2
          4.1
      
      5 nodes in tree
      TREE
      tree([[0, "0.0"], [1, "1.1"], [2, "2.2"], [2, "3.2"], [1, "4.1"]], :description=>true).should == expected_tree
    end

    test "with type directory renders" do
      expected_tree = <<-TREE.unindent
      0.0
      |-- 1.1
      |   |-- 2.2
      |   `-- 3.2
      `-- 4.1
      TREE
      tree([[0, "0.0"], [1, "1.1"], [2, "2.2"], [2, "3.2"], [1, "4.1"]], :type=>:directory).should == expected_tree
    end

    test "with type directory and multiple children per level renders" do
      expected_tree = <<-TREE.unindent
      0.0
      |-- 1.1
      |   |-- 2.2
      |   |   `-- 3.3
      |   `-- 4.2
      |       `-- 5.3
      `-- 6.1
      TREE
      tree([[0,'0.0'], [1,'1.1'], [2,'2.2'],[3,'3.3'],[2,'4.2'],[3,'5.3'],[1,'6.1']], :type=>:directory).should == expected_tree
    end

    test "with type number renders" do
      expected_tree = <<-TREE.unindent(6)
      1. 0
          1. 1
              1. 2
              2. 3
          2. 4 
      TREE
      tree([[0,'0'],[1,'1'],[2,'2'],[2,'3'],[1,'4']], :type=>:number)
    end
  end

  def mock_node(value, value_method)
    children = []
    value,children = *value if value.is_a?(Array)
    mock(value_method=>value, :children=>children.map {|e| mock_node(e, value_method)})
  end

  context "parent_child_tree" do
    test "with name value renders" do
      expected_tree = <<-TREE.unindent
      0.0
      |-- 1.1
      |-- 2.1
      |   `-- 3.2
      `-- 4.1
      TREE
      root = mock_node(['0.0', ['1.1', ['2.1', '3.2'], '4.1']], :name)
      Hirb::Helpers::ParentChildTree.render(root, :type=>:directory).should == expected_tree
    end
    
    test "with object_id value renders" do
      expected_tree = <<-TREE.unindent
      0.0
      |-- 1.1
      |-- 2.1
      |   `-- 3.2
      `-- 4.1
      TREE
      root = mock_node(['0.0', ['1.1', ['2.1', '3.2'], '4.1']], :object_id)
      Hirb::Helpers::ParentChildTree.render(root, :type=>:directory).should == expected_tree
    end

    test "with value_method option renders" do
      expected_tree = <<-TREE.unindent
      0.0
      |-- 1.1
      |-- 2.1
      |   `-- 3.2
      `-- 4.1
      TREE
      root = mock_node(['0.0', ['1.1', ['2.1', '3.2'], '4.1']], :blah)
      Hirb::Helpers::ParentChildTree.render(root, :type=>:directory, :value_method=>:blah).should == expected_tree
    end

    test "with children_method proc option renders" do
      expected_tree = <<-TREE.unindent
      1
      |-- 2
      |-- 3
      |-- 4
      `-- 5
      TREE
      Hirb::Helpers::ParentChildTree.render(1, :type=>:directory,
        :children_method=>lambda {|e| e == 1 ? (2..5).to_a : []}, :value_method=>:to_s)
    end
  end

  test "tree with parentless nodes renders ParentlessNodeError" do
    assert_raises(Hirb::Helpers::Tree::ParentlessNodeError) { tree([[0, "0.0"], [2, '1.2']], :validate=>true) }
  end
  
  test "tree with hash nodes missing level raises MissingLevelError" do
    assert_raises(Hirb::Helpers::Tree::Node::MissingLevelError) { tree([{:value=>'ok'}]) }
  end

  test "tree with hash nodes missing level raises MissingValueError" do
    assert_raises(Hirb::Helpers::Tree::Node::MissingValueError) { tree([{:level=>0}]) }
  end
end
