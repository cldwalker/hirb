module Hirb
  # This class is responsible for managing all view-related functionality.
  #
  # == Create a View
  # Let's create a simple view for Hash objects:
  #   $ irb -rubygems
  #   >> require 'hirb'
  #   =>true
  #   >> Hirb.enable
  #   =>nil
  #   >> require 'yaml'
  #   =>true
  #
  #   # A view method is the smallest view
  #   >> def yaml(output); output.to_yaml; end
  #   => nil
  #   # Add the view
  #   >> Hirb.add_view Hash, :method=>:yaml
  #   => true
  #
  #   # Hashes now appear as yaml
  #   >> {:a=>1, :b=>{:c=>3}}
  #   ---
  #   :a : 1
  #   :b : 
  #     :c : 3
  #   => true
  #
  # Another way of creating a view is a Helper class:
  #
  #   # Create yaml view class
  #   >> class Hirb::Helpers::Yaml; def self.render(output, options={}); output.to_yaml; end ;end
  #   =>nil
  #   # Add the view
  #   >> Hirb.add_view Hash, :class=>Hirb::Helpers::Yaml
  #   =>true
  #
  #   # Hashes appear as yaml like above ...
  #
  # == Configure a View
  # To configure the above Helper class as a view, either pass Hirb.enable a hash:
  #   # In .irbrc
  #   require 'hirb'
  #   # View class needs to come before enable()
  #   class Hirb::Helpers::Yaml; def self.render(output, options={}); output.to_yaml; end ;end
  #   Hirb.enable :output=>{"Hash"=>{:class=>"Hirb::Helpers::Yaml"}}
  #
  # Or create a config file at config/hirb.yml or ~/.hirb.yml:
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
  # For more about configuring Hirb, see the Config Files section in Hirb.
  module View
    DEFAULT_WIDTH = 120
    DEFAULT_HEIGHT = 40
    class<<self
      attr_accessor :render_method
      attr_reader :config

      # This activates view functionality i.e. the formatter, pager and size detection. If irb exists, it overrides irb's output
      # method with Hirb::View.view_output. When called multiple times, new configs are merged into the existing config.
      # If using Wirble, you should call this after it. The view configuration can be specified in a hash via a config file,
      # or as options to this method. In addition to the config keys mentioned in Hirb, options also take the following keys:
      # ==== Options:
      # * config_file: Name of config file(s) that are merged into existing config
      # Examples:
      #   Hirb.enable
      #   Hirb.enable :formatter=>false
      def enable(options={}, &block)
        Array(options.delete(:config_file)).each {|e|
          @new_config_file = true
          Hirb.config_files << e
        }
        enable_output_method unless @output_method
        merge_or_load_config options
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
        disable_output_method if @output_method
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
        if config[:ignore_errors]
          $stderr.puts "Hirb Error: #{e.message}"
          false
        else
          index = (obj = e.backtrace.find {|f| f =~ /^\(eval\)/}) ? e.backtrace.index(obj) : e.backtrace.length
          $stderr.puts "Hirb Error: #{e.message}", e.backtrace.slice(0,index).map {|e| "    " + e }
          true
        end
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
        config && config[:width] ? config[:width] : DEFAULT_WIDTH
      end

      # Current console height
      def height
        config && config[:height] ? config[:height] : DEFAULT_HEIGHT
      end

      # Current formatter config, storing a hash of all static views
      def formatter_config
        formatter.config
      end

      # Adds a view when View is enabled. See Formatter.add_view for more details.
      def add(klass, view_config)
        if enabled?
          formatter.add_view(klass, view_config)
        else
          puts "View must be enabled to add a view"
        end
      end

      #:stopdoc:
      def enable_output_method
        if defined?(Ripl) && Ripl.respond_to?(:started?) && Ripl.started?
          @output_method = true
          require 'ripl/hirb' unless defined? Ripl::Hirb
        elsif defined? IRB::Irb
          @output_method = true
          ::IRB::Irb.class_eval do
            alias_method :non_hirb_view_output, :output_value
            def output_value #:nodoc:
              Hirb::View.view_or_page_output(@context.last_value) || non_hirb_view_output
            end
          end
        end
      end

      def disable_output_method
        if defined?(IRB::Irb) && !defined? Ripl
          ::IRB::Irb.send :alias_method, :output_value, :non_hirb_view_output
        end
        @output_method = nil
      end

      def view_or_page_output(str)
        view_output(str) || page_output(str.inspect, true)
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
