module Hirb
  # A module which extends a Helper with the ability to have views for configured classes.
  # For classes to be configured for a helper, a helper must add view modules using add_module().
  # A helper can then get options for configured classes using get_options().
  module HelperView
    def get_options(obj)
      option_methods.each do |meth|
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

    def add_module(mod)
      new_methods = mod.instance_methods.select {|e| e.to_s =~ /_options$/ }.map {|e| e.to_s}
      return if new_methods.empty?
      extend mod
      option_methods.replace option_methods + new_methods
      update_config(new_methods)
    end

    def update_config(meths)
      output_config = meths.inject({}) {|t,e|
        t[method_to_class(e)] = {:class=>self, :ancestor=>true}; t
      }
      Formatter.default_config.merge! output_config
    end

    def method_to_class(meth)
      option_method_classes[meth] ||= Util.camelize meth.sub(/_options$/, '').gsub('__', '/')
    end

    def option_method_classes
      @option_method_classes ||= {}
    end

    def option_methods
      @option_methods ||= []
    end
  end
end