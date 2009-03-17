class Hirb::Helpers::ParentChildTree < Hirb::Helpers::Tree
  class <<self
    def render(root_node, options={})
      @value_method = options[:value_method] || (root_node.respond_to?(:name) ? :name : :object_id)
      @nodes = []
      save_node(root_node, 0)
      super(@nodes, options)
    end

    def save_node(node, level)
      @nodes << {:value=>node.send(@value_method), :level=>level}
      node.children.each {|e| save_node(e, level + 1)}
    end

    def node_value(node)
      node.send(@value_method)
    end
  end
end