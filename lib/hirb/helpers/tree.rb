# Base tree class which given an array of nodes produces different types of trees.
# The types of trees currently are:
# * basic:
#    0
#      1
#        2
#        3
#      4
# 
# * directory:
#    0
#    |-- 1
#    |   |-- 2
#    |   `-- 3
#    `-- 4
# 
# * number:
#    1. 0
#      1. 1
#        1. 2
#        2. 3
#      2. 4 
# 
# Tree nodes can be given as an array of arrays or an array of hashes.
# To render the above basic tree with an array of hashes:
#   Hirb::Helpers::Tree.render([{:value=>0, :level=>0}, {:value=>1, :level=>1}, {:value=>2, :level=>2}, 
#     {:value=>3, :level=>2}, {:value=>4, :level=>1}])
# Note from the hash keys that :level refers to the depth of the tree while :value refers to the text displayed
# for a node.
#
# To render the above basic tree with an array of arrays:
#   Hirb::Helpers::Tree.render([[0,0], [1,1], [2,2], [2,3], [1,4]])
# Note that the each array pair consists of the level and the value for the node.
class Hirb::Helpers::Tree
  class ParentlessNodeError < StandardError; end

  class <<self
    # Main method which renders a tree.
    # ==== Options:
    # [:type] Type of tree. Either :basic, :directory or :number. Default is :basic.
    # [:validate] Boolean to validate tree. Checks to see if all nodes have parents. Raises ParentlessNodeError if
    #             an invalid node is found. Default is false.
    # [:indent] Number of spaces to indent between levels for basic + number trees. Default is 4.
    # [:limit] Limits the level or depth of a tree that is displayed. Root node is level 0.
    # [:description] Displays brief description about tree ie how many nodes it has.
    # [:multi_line_nodes] Handles multi-lined nodes by indenting their newlines. Default is false.
    #  Examples:
    #     Hirb::Helpers::Tree.render([[0, 'root'], [1, 'child']], :type=>:directory)
    def render(nodes, options={})
      new(nodes, options).render
    end
  end

  # :stopdoc:
  attr_accessor :nodes
  
  def initialize(input_nodes, options={})
    @options = options
    @type = options[:type] || :basic
    if input_nodes[0].is_a?(Array)
      @nodes = input_nodes.map {|e| Node.new(:level=>e[0], :value=>e[1]) }
    else
      @nodes = input_nodes.map {|e| Node.new(e)}
    end
    @nodes.each_with_index {|e,i| e.merge!(:tree=>self, :index=>i)}
    @nodes.each {|e| e[:value] = e[:value].to_s }
    validate_nodes if options[:validate]
    self
  end

  def render
    body = render_tree
    body += render_description if @options[:description]
    body
  end
  
  def render_description
    "\n\n#{@nodes.length} #{@nodes.length == 1 ? 'node' : 'nodes'} in tree"
  end

  def render_tree
    @indent = ' ' * (@options[:indent] || 4 )
    @nodes = @nodes.select {|e| e[:level] <= @options[:limit] } if @options[:limit]
    case @type.to_s
    when 'directory' then render_directory
    when 'number'    then render_number
    else render_basic
    end
  end

  def render_nodes
    value_indent = @options[:multi_line_nodes] ? @indent : nil
    @nodes.map {|e| yield(e) + e.value(value_indent) }.join("\n")
  end

  def render_directory
    mark_last_nodes_per_level
    render_nodes {|e|
      value = ''
      unless e.root?
        value << e.render_parent_characters
        value << (e[:last_node] ? "`-- " : "|-- ")
      end
      value
    }
  end
  
  def render_number
    counter = {}
    @nodes.each {|e|
      parent_level_key = "#{(e.parent ||{})[:index]}.#{e[:level]}"
      counter[parent_level_key] ||= 0
      counter[parent_level_key] += 1
      e[:pre_value] = "#{counter[parent_level_key]}. "
    }
    render_nodes {|e| @indent * e[:level] + e[:pre_value] }
  end

  def render_basic
    render_nodes {|e| @indent * e[:level] }
  end

  def validate_nodes
    @nodes.each do |e|
      raise ParentlessNodeError if (e[:level] > e.previous[:level]) && (e[:level] - e.previous[:level]) > 1
    end
  end
  
  # walks tree accumulating last nodes per unique parent+level
  def mark_last_nodes_per_level
    @nodes.each {|e| e.delete(:last_node)}
    last_node_hash = @nodes.inject({}) {|h,e|
      h["#{(e.parent ||{})[:index]}.#{e[:level]}"] = e; h
    }
    last_node_hash.values.uniq.each {|e| e[:last_node] = true}
  end
  #:startdoc:
  class Node < ::Hash #:nodoc:
    class MissingLevelError < StandardError; end
    class MissingValueError < StandardError; end
    
    def initialize(hash)
      super
      raise MissingLevelError unless hash.has_key?(:level)
      raise MissingValueError unless hash.has_key?(:value)
      replace(hash)
    end

    def value(indent=nil)
      indent ? self[:value].gsub("\n", "\n#{indent * self[:level]}") : self[:value]
    end

    def parent
      self[:tree].nodes.slice(0 .. self[:index]).reverse.detect {|e| e[:level] < self[:level]}
    end

    def next
      self[:tree].nodes[self[:index] + 1]
    end

    def previous
      self[:tree].nodes[self[:index] - 1]
    end

    def root?; self[:level] == 0; end

    # refers to characters which connect parent nodes 
    def render_parent_characters
      parent_chars = []
      get_parents_character(parent_chars)
      parent_chars.reverse.map {|level| level + ' ' * 3 }.join('')
    end

    def get_parents_character(parent_chars)
      if self.parent
        parent_chars << (self.parent[:last_node] ? ' ' : '|') unless self.parent.root?
        self.parent.get_parents_character(parent_chars)
      end
    end
  end
end
