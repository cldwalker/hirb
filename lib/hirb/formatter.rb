module Hirb
  # A Formatter object formats an output object (using Formatter.format_output) into a string based on the views defined
  # for its class and/or ancestry.
  class Formatter
    TO_A_EXCEPTIONS = ['Hash', 'IO']

    class<<self
      # This config is used by Formatter.format_output to lazily load dynamic views defined with Hirb::DynamicView.
      # This hash has the same format as Formatter.config.
      attr_accessor :dynamic_config
    end
    self.dynamic_config = {}

    def initialize(additional_config={}) #:nodoc:
      @klass_config = {}
      @config = additional_config || {}
    end

    # A hash of Ruby class strings mapped to view hashes. A view hash must have at least a :method, :output_method
    # or :class option for a view to be applied to an output. A view hash has the following keys:
    # [*:method*] Specifies a global (Kernel) method to do the formatting.
    # [*:class*] Specifies a class to do the formatting, using its render() class method. If a symbol it's converted to a corresponding
    #            Hirb::Helpers::* class if it exists.
    # [*:output_method*] Specifies a method or proc to call on output before passing it to a helper. If the output is an array, it's applied
    #                    to every element in the array.
    # [*:options*] Options to pass the helper method or class.
    # [*:ancestor*] Boolean which when true causes subclasses of the output class to inherit its config. This doesn't effect the current
    #               output class. Defaults to false. This is used by ActiveRecord classes.
    # 
    #   Examples:
    #     {'WWW::Delicious::Element'=>{:class=>'Hirb::Helpers::ObjectTable', :ancestor=>true, :options=>{:max_width=>180}}}
    #     {'Date'=>{:class=>:auto_table, :ancestor=>true}}
    #     {'Hash'=>{:method=>:puts}}
    def config
      @config
    end

    # Adds the view for the given class and view hash config. See Formatter.config for valid keys for view hash.
    def add_view(klass, view_config)
      @klass_config.delete(klass)
      @config[klass.to_s] = view_config
      true
    end

    # This method looks for an output object's view in Formatter.config and then Formatter.dynamic_config.
    # If a view is found, a stringified view is returned based on the object. If no view is found, nil is returned. The options this
    # class takes are a view hash as described in Formatter.config. These options will be merged with any existing helper
    # config hash an output class has in Formatter.config. Any block given is passed along to a helper class.
    def format_output(output, options={}, &block)
      output_class = determine_output_class(output)
      options = parse_console_options(options) if options.delete(:console)
      options = Util.recursive_hash_merge(klass_config(output_class), options)
      _format_output(output, options, &block)
    end

    #:stopdoc:
    def _format_output(output, options, &block)
      output = options[:output_method] ? (output.is_a?(Array) ?
        output.map {|e| call_output_method(options[:output_method], e) } :
        call_output_method(options[:output_method], output) ) : output
      args = [output]
      args << options[:options] if options[:options] && !options[:options].empty?
      if options[:method]
        send(options[:method],*args)
      elsif options[:class] && (helper_class = Helpers.helper_class(options[:class]))
        helper_class.render(*args, &block)
      elsif options[:output_method]
        output
      end
    end

    def parse_console_options(options) #:nodoc:
      real_options = [:method, :class, :output_method].inject({}) do |h, e|
        h[e] = options.delete(e) if options[e]; h
      end
      real_options.merge! :options=>options
    end

    def determine_output_class(output)
      output.respond_to?(:to_a) && !TO_A_EXCEPTIONS.include?(output.class.to_s) ?
        Array(output)[0].class : output.class
    end

    def call_output_method(output_method, output)
      output_method.is_a?(Proc) ? output_method.call(output) : output.send(output_method)
    end

    # Internal view options built from user-defined ones. Options are built by recursively merging options from oldest
    # ancestors to the most recent ones.
    def klass_config(output_class)
      @klass_config[output_class] ||= build_klass_config(output_class)
    end

    def build_klass_config(output_class)
      output_ancestors = output_class.ancestors.map {|e| e.to_s}.reverse
      output_ancestors.pop
      hash = output_ancestors.inject({}) {|h, klass|
        add_klass_config_if_true(h, klass) {|c,klass| c[klass] && c[klass][:ancestor] }
      }
      add_klass_config_if_true(hash, output_class.to_s) {|c,klass| c[klass] }
    end

    def add_klass_config_if_true(hash, klass)
      if yield(@config, klass)
        Util.recursive_hash_merge hash, @config[klass]
      elsif yield(self.class.dynamic_config, klass)
        @config[klass] = self.class.dynamic_config[klass].dup # copy to local
        Util.recursive_hash_merge hash, self.class.dynamic_config[klass]
      else
        hash
      end
    end

    def reset_klass_config
      @klass_config = {}
    end
    #:startdoc:
  end
end
