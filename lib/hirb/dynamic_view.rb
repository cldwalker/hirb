module Hirb
  # This module extends a Helper with the ability to have dynamic views for configured output classes.
  # After a Helper has extended this module, it can use it within a render() by calling
  # dynamic_options() to get dynamically generated options for the object it's rendering. See Hirb::Helpers::AutoTable as an example.
  #
  # == Dynamic Views
  # Whereas normal views are generated from helpers with static helper options, dynamic views are generated from helpers and
  # dynamically generated helper options. Let's look at an example for Rails' ActiveRecord classes:
  #
  #   Hirb.add_dynamic_view("ActiveRecord::Base", :helper=>:auto_table) {|obj|
  #    {:fields=>obj.class.column_names} }
  #
  # From this dynamic view definition, _any_ ActiveRecord model class will render a table with the correct fields, since the fields
  # are extracted from the output object's class at runtime. Note that dynamic view definitions should return a hash of helper options.
  #
  # To define multiple dynamic views, create a Views module where each method ending in '\_view' maps to a class/module:
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
  #   Hirb.add_dynamic_view Hirb::Views::ORM, :helper=>:auto_table
  #
  # In this example, 'data_mapper__resource_view' maps to DataMapper::Resource and 'sequel__model_view' maps to Sequel::Model.
  # Note that when mapping method names to class names, '__' maps to '::' and '_' signals the next letter to be capitalized.
  module DynamicView
    # Add dynamic views to output class(es) for a given helper. If defining one view, the first argument is the output class
    # and a block defines the dynamic view. If defining multiple views, the first argument should be a Views::* module where
    # each method in the module ending in _view defines a view for an output class. To map output classes to method names in
    # a Views module, translate'::' to '__' and a capital letter translates to a '_' and a lowercase letter.
    # ==== Options:
    # [*:helper*] Required option. Helper class that view(s) use to format. Hirb::Helpers::AutoTable is the only valid
    #             helper among default helpers. Can be given in aliased form i.e. :auto_table -> Hirb::Helpers::AutoTable.
    #
    # Examples:
    #    Hirb.add_dynamic_view Hirb::Views::ORM, :helper=>:auto_table
    #    Hirb.add_dynamic_view("ActiveRecord::Base", :helper=>:auto_table) {|obj| {:fields=>obj.class.column_names} }
    def self.add(view, options, &block)
      raise ArgumentError, ":helper option is required" unless options[:helper]
      helper = Helpers.helper_class options[:helper]
      unless helper.is_a?(Module) && class << helper; self.ancestors; end.include?(self)
        raise ArgumentError, ":helper option must be a helper that has extended DynamicView"
      end
      mod = block ? generate_single_view_module(view, &block) : view
      raise ArgumentError, "'#{mod}' must be a module" unless mod.is_a?(Module)
      helper.add_module mod
    end

    def self.generate_single_view_module(output_mod, &block) #:nodoc:
      meth = class_to_method output_mod.to_s
      view_mod = meth.capitalize
      Views::Single.send(:remove_const, view_mod) if Views::Single.const_defined?(view_mod)
      mod = Views::Single.const_set(view_mod, Module.new)
      mod.send(:define_method, meth, block)
      mod
    end

    def self.class_to_method(mod) #:nodoc:
      mod.gsub(/(?!^)([A-Z])/) {|e| '_'+e }.gsub('::_', '__').downcase + '_view'
    end

    # Returns a hash of options based on dynamic views defined for the object's ancestry. If no config is found returns nil.
    def dynamic_options(obj)
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
      Formatter.dynamic_config.merge! output_config
    end

    def method_to_class(meth)
      view_method_classes[meth] ||= Util.camelize meth.sub(/_view$/, '').gsub('__', '/')
    end

    def view_method_classes
      @view_method_classes ||= {}
    end
    #:startdoc:

    # Stores view methods that a Helper has been given via DynamicView.add
    def view_methods
      @view_methods ||= []
    end
  end
end