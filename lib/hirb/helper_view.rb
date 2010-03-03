module Hirb
  # A module which extends a Helper with the ability to have helper-specific views for configured classes.
  # For classes to be configured for a helper, a helper must add view modules using add_module().
  # A helper can then get options for configured classes using get_options().
  module HelperView
    def get_options(obj)
      option_method_classes.each do |meth, klass|
        if obj.class.ancestors.include?(Util.any_const_get(klass))
          update_config(klass) unless View.formatter_config[klass]
          return send("#{meth}_options", obj)
        end
      end
    end

    def add_module(mod)
      new_methods = filter_option_methods mod.instance_methods
      return if new_methods.empty?
      extend mod
      option_methods.replace option_methods + new_methods
      update_config(new_methods)
    end

    def update_config(meths)
      output_config = meths.inject({}) {|t,e|
        t[method_to_class(e)] = {:class=>self, :ancestor=>true}; t
      }
      Formatter.default_config = output_config.merge Formatter.default_config
    end

    def option_method_classes
      option_methods.inject({}) {|t,e| t[e] = method_to_class(e); t }
    end

    def method_to_class(meth)
      Util.camelize meth.gsub('__', '/')
    end

    def option_methods
      @option_methods ||= []
    end

    def filter_option_methods(meths)
      meths.select {|e| e.to_s =~ /_options$/ }.map {|e| e.to_s.sub(/_options$/, '') }
    end
  end
end