class Hirb::Helpers::ParentChildTree < Hirb::Helpers::Tree
  class <<self
    # Starting with the given node, this builds a tree by recursively calling a children method.
    # Takes same options as Hirb::Helper::Table.render with some additional ones below.
    # ==== Options:
    # [:value_method] Method to call to display as a node's value. If not given, uses :name if node
    #                 responds to :name or defaults to :object_id.
    # [:children_method] Method or proc to call to obtain a node's children. Default is :children.
    def render(root_node, options={})
      @value_method = options[:value_method] || (root_node.respond_to?(:name) ? :name : :object_id)
      @children_method = options[:children_method] || :children
      @nodes = []
      build_node(root_node, 0)
      super(@nodes, options)
    end

    def build_node(node, level) #:nodoc:
      @nodes << {:value=>node.send(@value_method), :level=>level}
      children = @children_method.is_a?(Proc) ? @children_method.call(node) : node.send(@children_method)
      children.each {|e| build_node(e, level + 1)}
    end
  end
end
