module Hirb
  class Formatter
    attr_accessor :config
    def initialize(additional_config={})
      @config = Util.recursive_hash_merge default_config, additional_config || {}
    end

    def config=(value)
      @config = Util.recursive_hash_merge default_config, value || {}
    end

    def format_output(output, options={}, &block)
      output_class = determine_output_class(output)
      options = Util.recursive_hash_merge(output_class_options(output_class), options)
      output = options[:output_method] ? (output.is_a?(Array) ? output.map {|e| call_output_method(options[:output_method], e) } : 
        call_output_method(options[:output_method], output) ) : output
      args = [output]
      args << options[:options] if options[:options] && !options[:options].empty?
      if options[:method]
        new_output = send(options[:method],*args)
      elsif options[:class] && (view_class = Util.any_const_get(options[:class]))
        new_output = view_class.render(*args, &block)
      end
      new_output
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
    def output_class_options(output_class)
      @cached_config ||= {}
      @cached_config[output_class] ||= 
        begin
          output_ancestors_with_config = output_class.ancestors.map {|e| e.to_s}.select {|e| @config.has_key?(e)}
          @cached_config[output_class] = output_ancestors_with_config.reverse.inject({}) {|h, klass|
            (klass == output_class.to_s || @config[klass][:ancestor]) ? h.update(@config[klass]) : h
          }
        end
      @cached_config[output_class]
    end

    def reset_cached_config
      @cached_config = nil
    end
    
    def cached_config; @cached_config; end

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
    
  end
end