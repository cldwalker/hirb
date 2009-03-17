class Hirb::Helpers::Tree
  class <<self
    def render(nodes, options={})
      new(nodes, options).render
    end
  end

  attr_accessor :nodes
  
  def initialize(input_nodes, options={})
    @options = options
    @type = options[:type] || :basic
    if input_nodes[0].is_a?(Array)
      @nodes = input_nodes.map {|e| Node.new(:level=>e[0], :value=>e[1]) }
    else
      @nodes = input_nodes
    end
    @nodes.each_with_index {|e,i| e.merge!(:tree=>self, :index=>i)}
    self
  end

  def render
    case @type.to_s
    when 'filesystem'
      render_filesystem
    else
      render_basic
    end
  end

  def render_filesystem
    mark_last_nodes_per_level
    new_nodes = []
    @nodes.each_with_index {|e, i|
      value = ''
      unless e.root?
        value << e.render_parent_characters
        value << (e[:last_node] ? "`-- " : "|-- ")
      end
      value << e[:value]
      new_nodes << value
    }
    new_nodes.join("\n")
  end
  
  def render_basic
    @indent_char = @options[:indent_char] || "    "
    @nodes.map {|e| @indent_char * e[:level] + e[:value]}.join("\n")
  end
  
  def mark_last_nodes_per_level
    @nodes.each {|e| e.delete(:last_node)}
    saved_last_nodes = []
    last_node_hash = @nodes.inject({}) {|h,e|
      h[e[:level]] = e
      saved_last_nodes << e if e.next && e.next[:level] < e[:level]
      h
    }
    (saved_last_nodes + last_node_hash.values).uniq.each {|e| e[:last_node] = true}
  end

  class Node < ::Hash #:nodoc:
    def initialize(hash)
      super
      replace(hash)
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
      parent_chars.reverse.map {|level| level + ' ' * 3 }.to_s
    end

    def get_parents_character(parent_chars)
      if self.parent
        parent_chars << (self.parent[:last_node] ? ' ' : '|') unless self.parent.root?
        self.parent.get_parents_character(parent_chars)
      end
    end
  end
end