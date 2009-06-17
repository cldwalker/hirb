module Hirb
  # This class contains one method, render_output, which formats and renders the output its given from a console application.
  # However, this only happens for output classes that are configured to do so or if render_output is explicitly given
  # a view formatter. The hash with the following keys are valid for Hirb::View.config as well as the :view key mentioned in Hirb:
  # [:output] This hash is saved to formatter_config. It maps output classes to hashes that are passed to render_output. Thus these hashes
  #           take the same options as render_output. In addition it takes the following keys:
  #           * :ancestor- Boolean which if true allows all subclasses of the configured output class to inherit this config.
  # 
  #           Example: {'String'=>{:class=>'Hirb::Helpers::Table', :ancestor=>true, :options=>{:max_width=>180}}}
  module View
    DEFAULT_WIDTH = 150
    DEFAULT_HEIGHT = 50
    class<<self
      attr_accessor :config, :render_method

      # Overrides irb's output method with Hirb::View.render_output. Takes an optional
      # block which sets the view config.
      # Examples:
      #   Hirb.enable
      #   Hirb.enable {|c| c.output = {'String'=>{:class=>'Hirb::Helpers::Table'}} }
      def enable(options={}, &block)
        return puts("Already enabled.") if @enabled
        @enabled = true
        Hirb.config_file = options[:config_file] if options[:config_file]
        load_config(Hirb::HashStruct.block_to_hash(block))
        resize(config[:width], config[:height])
        if Object.const_defined?(:IRB)
          ::IRB::Irb.class_eval do
            alias :non_hirb_render_output  :output_value
            def output_value #:nodoc:
              Hirb::View.view_output(@context.last_value) || Hirb::View.page_output(@context.last_value.inspect, true) ||
                non_hirb_render_output
            end
          end
        end
      end

      # Indicates if Hirb::View is enabled.
      def enabled?
        @enabled || false
      end

      # Disable's Hirb's output by reverting back to irb's.
      def disable
        @enabled = false
        if Object.const_defined?(:IRB)
          ::IRB::Irb.class_eval do
            alias :output_value :non_hirb_render_output
          end
        end
      end

      # Toggles pager on or off. The pager only works while Hirb::View is enabled.
      def toggle_pager
        config[:pager] = !config[:pager]
      end

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
      
      # TODO: view must be enabled to call this
      # This is the main method of this class. This method searches for the first formatter it can apply
      # to the object in this order: output_method option, method option, class option. If a formatter is found it applies it to the object
      # and returns true. Returns false if no formatter found.
      # ==== Options:
      # [:method] Specifies a global (Kernel) method to do the formatting.
      # [:class] Specifies a class to do the formatting, using its render() class method. The render() method's arguments are the output and 
      #          an options hash.
      # [:output_method] Specifies a method or proc to call on output before passing it to a formatter.
      # [:options] Options to pass the formatter method or class.
      def view_output(output, options={})
        config[:formatter] && render_output(output, options)
      end

      # Captures STDOUT and renders it using render_method(). The main use case is to conditionally page captured stdout.
      def capture_and_render(&block)
        ::Hirb::View.render_method.call ::Hirb::Util.capture_stdout(&block)
      end

      # A lambda or proc which handles the final formatted object.
      # Although this puts the object by default, it could be set to do other things
      # ie write the formatted object to a file.
      def render_method
        @render_method ||= default_render_method
      end

      def reset_render_method
        @render_method = default_render_method
      end

      # Needs to be called for config changes to take effect. Reloads Hirb::Views classes and registers
      # most recent config changes.
      def reload_config
        current_config = self.config.dup.merge(:output=>formatter_config)
        load_config(current_config)
        formatter.config = config[:output]
      end
      
      # current console width
      def width
        config[:width] || DEFAULT_WIDTH
      end

      # current console height
      def height
        config[:height] || DEFAULT_HEIGHT
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
        @pager ||= Hirb::Pager.new(config[:width], config[:height], :pager_command=>config[:pager_command])
      end

      def pager=(value); @pager = value; end

      # Config hash which maps classes to view hashes. View hashes are the same as the options hash of render_output().
      def formatter_config
        formatter.config
      end

      def formatter
        @formatter ||= Hirb::Formatter.new(config[:output])
      end

      def formatter=(value); @formatter = value; end

      def load_config(additional_config={})
        self.config = Util.recursive_hash_merge default_config, additional_config
        formatter
        true
      end

      def config_loaded?; !!@config; end

      # Stores all view config. Current valid keys:
      #   :output- contains value of formatter_config
      def config=(value)
        @config = value
      end

      def config
        @config ||= {}
      end
      
      def default_render_method
        lambda {|output| page_output(output) || puts(output) }
      end

      def default_config
        Hirb::Util.recursive_hash_merge({:pager=>true, :formatter=>true}, Hirb.config[:view] || {})
      end
      #:startdoc:
    end
  end
  
  # Namespace for autoloaded views
  module Views
  end
end
