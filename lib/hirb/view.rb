module Hirb
  # This class is responsible for managing all view-related functionality.
  #
  # == Configure a View
  # Once you know {how to create views for a given class}[link:classes/Hirb/Formatter.html], you can configure
  # them to load at startup by either passing Hirb.enable a hash:
  #   # In .irbrc
  #   require 'hirb'
  #   # View class needs to come before enable()
  #   class Hirb::Helpers::Yaml; def self.render(output, options={}); output.to_yaml; end ;end
  #   Hirb.enable :output=>{"Hash"=>{:class=>"Hirb::Helpers::Yaml"}}
  #
  # Or by creating a config file at config/hirb.yml or ~/.hirb.yml:
  #   # The config file for the yaml example would look like:
  #   # ---
  #   # :output :
  #   #   Hash :
  #   #    :class : Hirb::Helpers::Yaml
  #
  #   # In .irbrc
  #   require 'hirb'
  #   # View class needs to come before enable()
  #   class Hirb::Helpers::Yaml; def self.render(output, options={}); output.to_yaml; end ;end
  #   Hirb.enable
  #
  # == Config Files
  # Hirb can have multiple config files defined by config_files(). These config files
  # have the following top level keys:
  # [:output] This hash is used by the formatter object. See Hirb::Formatter.config for its format.
  # [:width]  Width of the terminal/console. Defaults to Hirb::View::DEFAULT_WIDTH or possibly autodetected when Hirb is enabled.
  # [:height]  Height of the terminal/console. Defaults to Hirb::View::DEFAULT_HEIGHT or possibly autodetected when Hirb is enabled.
  # [:formatter] Boolean which determines if the formatter is enabled. Defaults to true.
  # [:pager] Boolean which determines if the pager is enabled. Defaults to true.
  # [:pager_command] Command to be used for paging. Command can have options after it i.e. 'less -r'.
  #                  Defaults to common pagers i.e. less and more if detected.
  #
  module View
    DEFAULT_WIDTH = 120
    DEFAULT_HEIGHT = 40
    class<<self
      attr_accessor :render_method
      attr_reader :config

      # This activates view functionality i.e. the formatter, pager and size detection. If irb exists, it overrides irb's output
      # method with Hirb::View.view_output. When called multiple times, new configs are merged into the existing config.
      # If using Wirble, you should call this after it. The view configuration
      # can be specified in a hash via a config file, as options to this method, as this method's block or any combination of these three.
      # In addition to the config keys mentioned in Hirb, the options also take the following keys:
      # ==== Options:
      # * config_file: Name of config file(s) that are merged into existing config
      # * output_method: Specify an object's class and instance method (separated by a period) to be realiased with
      #   hirb's view system. The instance method should take a string to be output. Default is IRB::Irb.output_value
      #   if using irb.
      # Examples:
      #   Hirb::View.enable
      #   Hirb::View.enable :formatter=>false, :output_method=>"Mini.output"
      #   Hirb::View.enable {|c| c.output = {'String'=>{:class=>'Hirb::Helpers::Table'}} }
      def enable(options={}, &block)
        Array(options.delete(:config_file)).each {|e|
          @new_config_file = true
          Hirb.config_files << e
        }
        enable_output_method(options.delete(:output_method))
        puts "Using a block with View.enable will be *deprecated* in the next release" if block_given?
        merge_or_load_config(Util.recursive_hash_merge(options, HashStruct.block_to_hash(block)))
        resize(config[:width], config[:height])
        @enabled = true
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
      rescue Exception=>e
        index = (obj = e.backtrace.find {|f| f =~ /^\(eval\)/}) ? e.backtrace.index(obj) : e.backtrace.length
        $stderr.puts "Hirb Error: #{e.message}", e.backtrace.slice(0,index).map {|e| "    " + e }
        true
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

      #:stopdoc:
      def enable_output_method(meth)
        if (meth ||= Object.const_defined?(:IRB) ? "IRB::Irb.output_value" : false) && !@output_method
          @output_method = meth
          alias_output_method(@output_method)
        end
      end

      def unalias_output_method(output_method)
        klass, klass_method = output_method.split(".")
        eval %[
          ::#{klass}.class_eval do
            alias_method :#{klass_method}, :non_hirb_view_output
          end
        ]
        @output_method = nil
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

      def merge_or_load_config(additional_config={})
        if @config && (@new_config_file || !additional_config.empty?)
          Hirb.config = nil
          load_config Util.recursive_hash_merge(@config, additional_config)
          @new_config_file = false
        elsif !@enabled
          load_config(additional_config)
        end
      end

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
end