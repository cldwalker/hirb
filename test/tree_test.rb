require File.join(File.dirname(__FILE__), 'test_helper')

describe "Tree helpers:" do
  def tree(*args)
    Helpers::Tree.render(*args)
  end
  
  describe "basic tree" do
    it "with hash nodes renders" do
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
  
    it "with array nodes renders" do
      expected_tree = <<-TREE.unindent(6)
      0.0
          1.1
              2.2
              3.2
          4.1
      TREE
      tree([[0, "0.0"], [1, "1.1"], [2, "2.2"], [2, "3.2"], [1, "4.1"]]).should == expected_tree
    end
    
    it "with non-string values renders" do
      expected_tree = <<-TREE.unindent(6)
      0.0
          1.1
              2.2
              3.2
          4.1
      TREE
      tree([[0,0.0],[1,1.1],[2,2.2],[2,3.2],[1,4.1]]).should == expected_tree
    end

    it "with indent option renders" do
      expected_tree = <<-TREE.unindent(6)
      0.0
        1.1
          2.2
          3.2
        4.1
      TREE
      tree([[0, "0.0"], [1, "1.1"], [2, "2.2"], [2, "3.2"], [1, "4.1"]], :indent=>2).should == expected_tree
    end

    it "with limit option renders" do
      expected_tree = <<-TREE.unindent(6)
      0.0
          1.1
          4.1
      TREE
      tree([[0, "0.0"], [1, "1.1"], [2, "2.2"], [2, "3.2"], [1, "4.1"]], :limit=>1).should == expected_tree
    end

    it "with description option renders" do
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

    it "with type directory renders" do
      expected_tree = <<-TREE.unindent
      0.0
      |-- 1.1
      |   |-- 2.2
      |   `-- 3.2
      `-- 4.1
      TREE
      tree([[0, "0.0"], [1, "1.1"], [2, "2.2"], [2, "3.2"], [1, "4.1"]], :type=>:directory).should == expected_tree
    end

    it "with type directory and multiple children per level renders" do
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

    it "with type number renders" do
      expected_tree = <<-TREE.unindent(6)
      1. 0
          1. 1
              1. 2
              2. 3
          2. 4
      TREE
      tree([[0,'0'],[1,'1'],[2,'2'],[2,'3'],[1,'4']], :type=>:number).should == expected_tree
    end

    it "with multi-line nodes option renders" do
      expected_tree = <<-TREE.unindent(6)
      parent
          +-------+
          | value |
          +-------+
          | 1     |
          | 2     |
          | 3     |
          +-------+
              indented
              stuff
      TREE
      node1 = "+-------+\n| value |\n+-------+\n| 1     |\n| 2     |\n| 3     |\n+-------+"
      tree([ [0, 'parent'],[1, node1],[2, "indented\nstuff"]], :multi_line_nodes=>true).should == expected_tree
    end
  end

  def mock_node(value, value_method)
    children = []
    value,children = *value if value.is_a?(Array)
    mock(value_method=>value, :children=>children.map {|e| mock_node(e, value_method)})
  end

  describe "parent_child_tree" do
    it "with name value renders" do
      expected_tree = <<-TREE.unindent
      0.0
      |-- 1.1
      |-- 2.1
      |   `-- 3.2
      `-- 4.1
      TREE
      root = mock_node(['0.0', ['1.1', ['2.1', ['3.2']], '4.1']], :name)
      Helpers::ParentChildTree.render(root, :type=>:directory).should == expected_tree
    end
    
    it "with value_method option renders" do
      expected_tree = <<-TREE.unindent
      0.0
      |-- 1.1
      |-- 2.1
      |   `-- 3.2
      `-- 4.1
      TREE
      root = mock_node(['0.0', ['1.1', ['2.1', ['3.2']], '4.1']], :blah)
      Helpers::ParentChildTree.render(root, :type=>:directory, :value_method=>:blah).should == expected_tree
    end

    it "with children_method proc option renders" do
      expected_tree = <<-TREE.unindent
      1
      |-- 2
      |-- 3
      |-- 4
      `-- 5
      TREE
      Helpers::ParentChildTree.render(1, :type=>:directory,
        :children_method=>lambda {|e| e == 1 ? (2..5).to_a : []}, :value_method=>:to_s).should == expected_tree
    end
  end

  it "tree with parentless nodes renders ParentlessNodeError" do
    lambda { tree([[0, "0.0"], [2, '1.2']], :validate=>true) }.should.raise(Helpers::Tree::ParentlessNodeError)
  end
  
  it "tree with hash nodes missing level raises MissingLevelError" do
    lambda { tree([{:value=>'ok'}]) }.should.raise(Helpers::Tree::Node::MissingLevelError)
  end

  it "tree with hash nodes missing level raises MissingValueError" do
    lambda { tree([{:level=>0}]) }.should.raise(Helpers::Tree::Node::MissingValueError)
  end
end