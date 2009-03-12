module Hirb
  module View
    class<<self
      attr_accessor :config, :render_method

      # Overrides irb's output method with Hirb::View.render_output. Takes an optional
      # block which sets the view config.
      # Examples:
      #   Hirb.enable
      #   Hirb.enable {|c| c.output = {'String'=>{:class=>'Hirb::Helpers::Table'}} }
      def enable(&block)
        return puts("Already enabled.") if @enabled
        @enabled = true
        load_config(Hirb::HashStruct.block_to_hash(block))
        ::IRB::Irb.class_eval do
          alias :non_hirb_render_output  :output_value
          def output_value #:nodoc:
            Hirb::View.render_output(@context.last_value) || non_hirb_render_output
          end
        end
      end
      
      # Disable's Hirb's output by reverting back to irb's.
      def disable
        @enabled = false
        ::IRB::Irb.class_eval do
          alias :output_value :non_hirb_render_output
        end
      end
      
      # This is the main method of this class. This method searches for the first formatter it can apply
      # to the object in this order: local block, method option, class option. If a formatter is found it applies it to the object
      # and returns true. Returns false if no formatter found.
      # ==== Options:
      # [:method] Specifies a global (Kernel) method to do the formatting.
      # [:class] Specifies a class to do the formatting, using its render() class method.
      # [:options] Options to pass the formatter method or class.
      def render_output(output, options={}, &block)
        if block && block.arity > 0
          formatted_output = block.call(output)
          render_method.call(formatted_output)
          true
        elsif (formatted_output = format_output(output, options))
          render_method.call(formatted_output)
          true
        else
          false
        end
      end

      # A lambda or proc which handles the final formatted object.
      # Although this puts the object by default, it could be set to do other things
      # ie write the formatted object to a file.
      def render_method
        @render_method ||= lambda {|output| puts output}
      end

      # Config hash which maps classes to view hashes. View hashes are the same as the options hash of render_output().
      def output_config
        @config[:output]
      end
      
      # Needs to be called for config changes to take effect. Reloads Hirb::Views classes and registers
      # most recent config changes.
      def reload_config
        current_config = self.config.dup.merge(:output=>output_config)
        load_config(current_config)
      end

      #:stopdoc:
      def console_render_output(output, options={}, &block)
        # iterates over format_output options that aren't :options
        real_options = [:method, :class].inject({}) do |h, e|
          h[e] = options.delete(e) if options[e]
          h
        end
        render_output(output, real_options.merge(:options=>options), &block)
      end

      def format_output(output, options={})
        output_class = determine_output_class(output)
        options = output_class_options(output_class).merge(options)
        args = [output]
        args << options[:options] if options[:options] && !options[:options].empty?
        if options[:method]
          new_output = send(options[:method],*args)
        elsif options[:class] && (view_class = Util.any_const_get(options[:class]))
          new_output = view_class.render(*args)
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

      # Loads config
      def load_config(additional_config={})
        new_config = default_config
        new_config[:output].merge!(additional_config.delete(:output) || {})
        self.config = new_config.merge(additional_config)
        true
      end

      # Stores all view config. Current valid keys:
      #   :output- contains value of output_config
      def config=(value)
        reset_cached_output_config
        @config = value
      end
      
      def reset_cached_output_config
        @cached_output_config = nil
      end
      
      def output_config=(value)
        @config[:output] = value
      end

      # Internal view options built from user-defined ones. Options are built by recursively merging options from oldest
      # ancestors to the most recent ones.
      def output_class_options(output_class)
        @cached_output_config ||= {}
        @cached_output_config[output_class] ||= 
          begin
            output_ancestors_with_config = output_class.ancestors.map {|e| e.to_s}.select {|e| output_config.has_key?(e)}
            @cached_output_config[output_class] = output_ancestors_with_config.reverse.inject({}) {|h, klass|
              (klass == output_class.to_s || output_config[klass][:ancestor]) ? h.update(output_config[klass]) : h
            }
          end
        @cached_output_config[output_class]
      end
      
      def cached_output_config; @cached_output_config; end

      def default_config
        conf = Hirb.config[:view] || {}
        conf[:output] = default_output_config.merge(conf[:output] || {})
        conf
      end

      def default_output_config
        Hirb::Views.constants.inject({}) {|h,e|
          output_class = e.to_s.gsub("_", "::")
          if (views_class = Hirb::Views.const_get(e)) && views_class.respond_to?(:render)
            default_options = views_class.respond_to?(:default_options) ? views_class.default_options : {}
            h[output_class] = default_options.merge({:class=>"Hirb::Views::#{e}"})
          end
          h
        }
      end
      #:startdoc:
    end
  end
  
  # Namespace for autoloaded views
  module Views
  end
end
