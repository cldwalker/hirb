module Hirb
  # This class is responsible for managing all view-related functionality. Its functionality is determined by the configuration file
  # explained in Hirb or passed to enable().
  module View
    DEFAULT_WIDTH = 120
    DEFAULT_HEIGHT = 40
    class<<self
      attr_accessor :config, :render_method

      # This is the main on and off switch for the formatter and pager, height + width TODO.
      # If irb exists, it overrides irb's output method with Hirb::View.view_output. Takes an optional
      # block which sets the view config. If enabling Wirble, you should call this after it.
      # Options: TODO
      # Examples:
      #   Hirb.enable
      #   Hirb.enable {|c| c.output = {'String'=>{:class=>'Hirb::Helpers::Table'}} }
      def enable(options={}, &block)
        return puts("Already enabled.") if @enabled
        @enabled = true
        Hirb.config_file = options[:config_file] if options[:config_file]
        load_config(HashStruct.block_to_hash(block))
        resize(config[:width], config[:height])
        if Object.const_defined?(:IRB)
          ::IRB::Irb.class_eval do
            alias :non_hirb_view_output  :output_value
            def output_value #:nodoc:
              Hirb::View.view_output(@context.last_value) || Hirb::View.page_output(@context.last_value.inspect, true) ||
                non_hirb_view_output
            end
          end
        end
      end

      # Indicates if Hirb::View is enabled.
      def enabled?
        @enabled || false
      end

      # Disable's Hirb's output and revert's irb's output method if irb exists.
      def disable
        @enabled = false
        if Object.const_defined?(:IRB)
          ::IRB::Irb.class_eval do
            alias :output_value :non_hirb_view_output
          end
        end
      end

      # Toggles pager on or off. The pager only works while Hirb::View is enabled.
      def toggle_pager
        config[:pager] = !config[:pager]
      end

      # Toggles formatter on or off.
      def toggle_formatter
        config[:formatter] = !config[:formatter]
      end

      # Resizes the console width and height for use with the table + pager i.e. after having resized the console window. *nix users
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
      # Although this puts the object by default, it could be set to do other things
      # i.e. write the formatted object to a file.
      def render_method
        @render_method ||= default_render_method
      end

      def reset_render_method
        @render_method = default_render_method
      end
      
      # current console width
      def width
        config ? config[:width] : DEFAULT_WIDTH
      end

      # current console height
      def height
        config ? config[:height] : DEFAULT_HEIGHT
      end

      #:stopdoc:
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

      # Config hash which maps classes to view hashes. View hashes are the same as the options hash of render_output().
      def formatter_config
        formatter.config
      end

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
