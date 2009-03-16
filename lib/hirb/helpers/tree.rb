class Hirb::Helpers::Tree
  class Node < ::Hash
    def initialize(hash)
      super
      replace(hash)
    end

    def parent
      self[:tree].nodes.slice(0 .. self[:index]).reverse.detect {|e| e[:level] < self[:level]}
    end
    
    def render_parent_levels
      body = []
      render_parent_level(body)
      body.reverse
    end
    
    def render_parent_level(body)
      if self.parent
        body << (self.parent[:last_node] ? '|' : ' ') unless self.parent.root?
        self.parent.render_parent_level(body)
      end
      body
    end
    
    def render_parent_markers
      render_parent_levels.map {|level| level + ' ' * 3 }.to_s
    end
    
    def root?; self[:level] == 0; end
  end
  
  def initialize(input_nodes, options={})
    @indent_char = options[:indent_char] || "\t"
    if input_nodes[0].is_a?(Array)
      @nodes = input_nodes.map {|e| Node.new(:level=>e[0], :value=>e[1]) }
    else
      @nodes = input_nodes
    end
    @nodes.each_with_index {|e,i| e.merge!(:tree=>self, :index=>i)}
    self
  end
  
  attr_accessor :nodes

  def mark_last_nodes_per_level
    @nodes.each {|e| e.delete(:last_node)}
    last_node_hash = @nodes.inject({}) {|h,e|
      h[e[:level]] = e; h
    }
    last_node_hash.values.each {|e| e[:last_node] = true}
  end
  
  def render_ascii
    mark_last_nodes_per_level
    new_nodes = []
    @nodes.each_with_index {|e, i|
      value = ''
      if e[:level] > 0
        value << e.render_parent_markers
        value << (e[:last_node] ? "`-- " : "|-- ")
      end
      value << e[:value]
      new_nodes << value
    }
    new_nodes.join("\n")
  end
  
  def render_simple
    @nodes.map {|e| @indent_char * e[:level] + e[:value]}.join("\n")
  end
  
  def render
    render_ascii
  end
  
  class <<self
    def render(nodes, options={})
      new(nodes, options).render
    end
  end
end