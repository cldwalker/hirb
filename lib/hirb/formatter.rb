module Hirb
  # This class is used by the View to format an output into a string. The formatter object looks for an output's class config in config()
  # and if found applies a helper to the output.
  
  class Formatter
    def initialize(additional_config={})
      @klass_config = {}
      @config = Util.recursive_hash_merge default_config, additional_config || {}
    end

    # A hash of Ruby class strings mapped to helper config hashes. A helper config hash must have at least a :method or :class option
    # for a helper to be applied to an output. A helper config hash has the following keys:
    # [:method] Specifies a global (Kernel) method to do the formatting.
    # [:class] Specifies a class to do the formatting, using its render() class method. If a symbol it's converted to a corresponding
    #          Hirb::Helpers::* class if it exists.
    # [:output_method] Specifies a method or proc to call on output before passing it to a helper. If the output is an array, it's applied
    #                  to every element in the array.
    # [:options] Options to pass the helper method or class.
    # [:ancestor] Boolean which when true causes subclasses of the output class to inherit its config. This doesn't effect the current 
    #             output class. Defaults to false. This is used by ActiveRecord classes.
    # 
    #   Examples:
    #     {'WWW::Delicious::Element'=>{:class=>'Hirb::Helpers::ObjectTable', :ancestor=>true, :options=>{:max_width=>180}}}
    #     {'Date'=>{:class=>:auto_table, :ancestor=>true}}
    def config
      @config
    end

    def format_class(klass, helper_config)
      @klass_config.delete(klass)
      @config[klass.to_s] = helper_config
      true
    end

    # Reloads autodetected Hirb::Views
    def reload
      @config = Util.recursive_hash_merge default_config, @config
    end

    # This is the main method of this class. The formatter looks for the first helper in its config for the given output class.
    # If a helper is found, the output is converted by the helper into a string and returned. If not, nil is returned. The options
    # this class takes are a helper config hash as described in config(). These options will be merged with any existing helper config hash
    # an output class has in config(). Any block given is passed along to a helper class.
    def format_output(output, options={}, &block)
      output_class = determine_output_class(output)
      options = Util.recursive_hash_merge(klass_config(output_class), options)
      output = options[:output_method] ? (output.is_a?(Array) ? output.map {|e| call_output_method(options[:output_method], e) } : 
        call_output_method(options[:output_method], output) ) : output
      args = [output]
      args << options[:options] if options[:options] && !options[:options].empty?
      if options[:method]
        new_output = send(options[:method],*args)
      elsif options[:class] && (helper_class = determine_helper_class(options[:class]))
        new_output = helper_class.render(*args, &block)
      end
      new_output
    end

    #:stopdoc:

    def determine_helper_class(klass)
      if klass.is_a?(Symbol) && (helper_class = Helpers.constants.find {|e| e == Util.camelize(klass.to_s)})
        klass = "Hirb::Helpers::#{helper_class}"
      end
      Util.any_const_get(klass)
    end

    def determine_output_class(output)
      if output.is_a?(Array)
        output[0].class
      else
        output.class
      end
    end

    def call_output_method(output_method, output)
      output_method.is_a?(Proc) ? output_method.call(output) : output.send(output_method)
    end

    # Internal view options built from user-defined ones. Options are built by recursively merging options from oldest
    # ancestors to the most recent ones.
    def klass_config(output_class)
      @klass_config[output_class] ||= begin
        output_ancestors_with_config = output_class.ancestors.map {|e| e.to_s}.select {|e| @config.has_key?(e)}
        @klass_config[output_class] = output_ancestors_with_config.reverse.inject({}) {|h, klass|
          (klass == output_class.to_s || @config[klass][:ancestor]) ? h.update(@config[klass]) : h
        }
      end
    end

    def reset_klass_config
      @klass_config = {}
    end

    def default_config
      Views.constants.inject({}) {|h,e|
        output_class = e.to_s.gsub("_", "::")
        if (views_class = Views.const_get(e)) && views_class.respond_to?(:render)
          default_options = views_class.respond_to?(:default_options) ? views_class.default_options : {}
          h[output_class] = default_options.merge({:class=>"Hirb::Views::#{e}"})
        end
        h
      }
    end
    #:startdoc:
  end
end