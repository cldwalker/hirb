module Hirb
  # This module extends a Helper with the ability to have dynamic views for configured output classes.
  # After a Helper has extended this module, it can use it within a render() by calling
  # default_options() to get default options for the object it's rendering. See Hirb::Helpers::AutoTable as an example.
  #
  # A view for a given output class and helper is a method that generates a hash of helper options to be passed
  # to the helper via default_options. A view method expects the object it's supposed to render.
  # To define multiple views create a views module:
  #
  #   module Hirb::Views::ORM
  #     def data_mapper__resource_view(obj)
  #       {:fields=>obj.class.properties.map {|e| e.name }}
  #     end
  #
  #     def sequel__model_view(obj)
  #       {:fields=>obj.class.columns}
  #     end
  #   end
  #
  #   Hirb.add :views=>Hirb::Views::ORM, :helper=>:auto_table
  #
  # Each method that ends in '_view' defined a view for a given output class. These methods map to their output
  # classes, with '__' being converted to '::' and '_' signaling the next letter to be capitalized. In the above
  # examples, 'data_mapper__resource_view' maps to DataMapper::Resource and 'sequel__model_view' maps to Sequel::Model.
  #
  # To generate a single view, pass a block to Hirb.add:
  #   Hirb.add(:view=>"DataMapper::Resource", :helper=>:auto_table) do |obj|
  #     {:fields=>obj.class.properties.map {|e| e.name }}
  #   end
  module HelperView
    # Add views to output class(es) for a given helper. Either :helper or :method option is required and either
    # :views or :view option is required.
    # ==== Options:
    # [*:helper*] Helper class that view(s) use to format.
    #             Can be given in aliased form i.e. :auto_table -> Hirb::Helpers::AutoTable.
    # [*:method*] Top-level (main) method used to format a view.
    # [*:view*] Output class. Must be given with a block.
    # [*:views*] Module containg views for multiple output classes. Output classes extracted from method names.
    # Examples:
    #    Hirb.add :views=>Hirb::Views::ORM, :helper=>:auto_table
    #    Hirb.add(:view=>"DataMapper::Resource", :helper=>:auto_table) do |obj|
    #     {:fields=>obj.class.properties.map {|e| e.name }}
    #    end
    def self.add(options, &block)
      raise ArgumentError, ":views or :view option required" unless options[:views] or options[:view]
      raise ArgumentError, ":helper or :method option is required" unless options[:helper] or options[:method]
      if options[:views] || (options[:view] && block)
        helper = Helpers.helper_class options[:helper]
        unless helper.is_a?(Module) && class << helper; self.ancestors; end.include?(self)
          raise ArgumentError, ":helper option must be a helper that has extended HelperView"
        end
        mod = options[:views] || generate_single_view_module(options[:view], &block)
        raise ArgumentError, ":views option must be a module" unless mod.is_a?(Module)
        helper.add_module mod
      else
        new_config = options[:method] ? {:method=>options[:method]} :
          {:class=>Helpers.helper_class(options[:helper])}
        Formatter.default_config.merge! options[:view].to_s=>new_config
      end
      true
    end

    def self.generate_single_view_module(output_mod, &block) #:nodoc:
      output_class = Util.any_const_get(output_mod)
      mod_name = output_class.to_s.gsub("::","__")
      Views::Single.send(:remove_const, mod_name) if Views::Single.const_defined?(mod_name)
      mod = Views::Single.const_set(mod_name, Module.new)
      mod.send(:define_method, "#{mod_name}_view".downcase, block)
      mod
    end

    # Returns a hash of default options based on the object's class config. If no config is found returns nil.
    def default_options(obj)
      view_methods.each do |meth|
        if obj.class.ancestors.map {|e| e.to_s }.include?(method_to_class(meth))
          begin
            return send(meth, obj)
          rescue
            raise "View failed to generate for '#{method_to_class(meth)}' "+
              "while in '#{meth}' with error:\n#{$!.message}"
          end
        end
      end
      nil
    end

    #:stopdoc:
    def add_module(mod)
      new_methods = mod.instance_methods.select {|e| e.to_s =~ /_view$/ }.map {|e| e.to_s}
      return if new_methods.empty?
      extend mod
      view_methods.replace(view_methods + new_methods).uniq!
      update_config(new_methods)
    end

    def update_config(meths)
      output_config = meths.inject({}) {|t,e|
        t[method_to_class(e)] = {:class=>self, :ancestor=>true}; t
      }
      Formatter.default_config.merge! output_config
    end

    def method_to_class(meth)
      option_method_classes[meth] ||= Util.camelize meth.sub(/_view$/, '').gsub('__', '/')
    end

    def option_method_classes
      @option_method_classes ||= {}
    end
    #:startdoc:

    # Stores option methods that a Helper has been given via HelperView.add
    def view_methods
      @view_methods ||= []
    end
  end
end