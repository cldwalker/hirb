module Hirb
  # This class is responsible for managing all view-related functionality. Its functionality is determined by setting up a configuration file
  # as explained in Hirb and/or passed configuration directly to Hirb.enable. Most of the functionality in this class is dormant until enabled.
  module View
    DEFAULT_WIDTH = 120
    DEFAULT_HEIGHT = 40
    class<<self
      attr_accessor :render_method
      attr_reader :config

      # This activates view functionality i.e. the formatter, pager and size detection. If irb exists, it overrides irb's output
      # method with Hirb::View.view_output. If using Wirble, you should call this after it. The view configuration
      # can be specified in a hash via a config file, as options to this method, as this method's block or any combination of these three.
      # In addition to the config keys mentioned in Hirb, the options also take the following keys:
      # Options:
      # * config_file: Name of config file to read.
      # * output_method: Specify an object's class and instance method (separated by a period) to be realiased with
      #   hirb's view system. The instance method should take a string to be output. Default is IRB::Irb.output_value
      #   if using irb.
      # Examples:
      #   Hirb::View.enable
      #   Hirb::View.enable :formatter=>false, :output_method=>"Mini.output"
      #   Hirb::View.enable {|c| c.output = {'String'=>{:class=>'Hirb::Helpers::Table'}} }
      def enable(options={}, &block)
        return puts("Already enabled.") if @enabled
        @enabled = true
        Hirb.config_file = options.delete(:config_file) if options[:config_file]
        @output_method = "IRB::Irb.output_value" if Object.const_defined?(:IRB)
        @output_method = options.delete(:output_method) if options[:output_method]
        load_config(Util.recursive_hash_merge(options, HashStruct.block_to_hash(block)))
        resize(config[:width], config[:height])
        alias_output_method(@output_method) if @output_method
        true
      end

      # Indicates if Hirb::View is enabled.
      def enabled?
        @enabled || false
      end

      # Disable's Hirb's output and revert's irb's output method if irb exists.
      def disable
        @enabled = false
        unalias_output_method(@output_method) if @output_method
        false
      end

      # Toggles pager on or off. The pager only works while Hirb::View is enabled.
      def toggle_pager
        config[:pager] = !config[:pager]
      end

      # Toggles formatter on or off.
      def toggle_formatter
        config[:formatter] = !config[:formatter]
      end

      # Resizes the console width and height for use with the table and pager i.e. after having resized the console window. *nix users
      # should only have to call this method. Non-*nix users should call this method with explicit width and height. If you don't know
      # your width and height, in irb play with "a"* width to find width and puts "a\n" * height to find height.
      def resize(width=nil, height=nil)
        config[:width], config[:height] = determine_terminal_size(width, height)
        pager.resize(config[:width], config[:height])
      end
      
      # This is the main method of this class. When view is enabled, this method searches for a formatter it can use for the output and if
      # successful renders it using render_method(). The options this method takes are helper config hashes as described in 
      # Hirb::Formatter.format_output(). Returns true if successful and false if no formatting is done or if not enabled.
      def view_output(output, options={})
        enabled? && config[:formatter] && render_output(output, options)
      end

      # Captures STDOUT and renders it using render_method(). The main use case is to conditionally page captured stdout.
      def capture_and_render(&block)
        render_method.call Util.capture_stdout(&block)
      end

      # A lambda or proc which handles the final formatted object.
      # Although this pages/puts the object by default, it could be set to do other things
      # i.e. write the formatted object to a file.
      def render_method
        @render_method ||= default_render_method
      end

      # Resets render_method back to its default.
      def reset_render_method
        @render_method = default_render_method
      end
      
      # Current console width
      def width
        config ? config[:width] : DEFAULT_WIDTH
      end

      # Current console height
      def height
        config ? config[:height] : DEFAULT_HEIGHT
      end

      # Current formatter config
      def formatter_config
        formatter.config
      end

      # Sets the helper config for the given output class.
      def format_class(klass, helper_config)
        formatter.format_class(klass, helper_config)
      end

      #:stopdoc:
      def unalias_output_method(output_method)
        klass, klass_method = output_method.split(".")
        eval %[
          ::#{klass}.class_eval do
            alias_method :#{klass_method}, :non_hirb_view_output
          end
        ]
      end

      def alias_output_method(output_method)
        klass, klass_method = output_method.split(".")
        eval %[
          ::#{klass}.class_eval do
            alias_method :non_hirb_view_output, :#{klass_method}
            if '#{klass}' == "IRB::Irb"
              def #{klass_method} #:nodoc:
                Hirb::View.view_output(@context.last_value) || Hirb::View.page_output(@context.last_value.inspect, true) ||
                  non_hirb_view_output
              end
            else
              def #{klass_method}(output_string) #:nodoc:
                Hirb::View.view_output(output_string) || Hirb::View.page_output(output_string.inspect, true) ||
                  non_hirb_view_output(output_string)
              end
            end
          end
        ]
      end

      def render_output(output, options={})
        if (formatted_output = formatter.format_output(output, options))
          render_method.call(formatted_output)
          true
        else
          false
        end
      end

      def determine_terminal_size(width, height)
        detected  = (width.nil? || height.nil?) ? Util.detect_terminal_size || [] : []
        [width || detected[0] || DEFAULT_WIDTH , height || detected[1] || DEFAULT_HEIGHT]
      end

      def page_output(output, inspect_mode=false)
        if enabled? && config[:pager] && pager.activated_by?(output, inspect_mode)
          pager.page(output, inspect_mode)
          true
        else
          false
        end
      end

      def pager
        @pager ||= Pager.new(config[:width], config[:height], :pager_command=>config[:pager_command])
      end

      def pager=(value); @pager = value; end

      def formatter(reload=false)
        @formatter = reload || @formatter.nil? ? Formatter.new(config[:output]) : @formatter
      end

      def formatter=(value); @formatter = value; end

      def load_config(additional_config={})
        @config = Util.recursive_hash_merge default_config, additional_config
        formatter(true)
        true
      end

      def config_loaded?; !!@config; end

      def config
        @config
      end
      
      def default_render_method
        lambda {|output| page_output(output) || puts(output) }
      end

      def default_config
        Util.recursive_hash_merge({:pager=>true, :formatter=>true}, Hirb.config || {})
      end
      #:startdoc:
    end
  end
  
  # Namespace for autoloaded views
  module Views
  end
end
