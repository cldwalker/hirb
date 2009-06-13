module Hirb
  # This class contains one method, render_output, which formats and renders the output its given from a console application.
  # However, this only happens for output classes that are configured to do so or if render_output is explicitly given
  # a view formatter. The hash with the following keys are valid for Hirb::View.config as well as the :view key mentioned in Hirb:
  # [:output] This hash is saved to output_config. It maps output classes to hashes that are passed to render_output. Thus these hashes
  #           take the same options as render_output. In addition it takes the following keys:
  #           * :ancestor- Boolean which if true allows all subclasses of the configured output class to inherit this config.
  # 
  #           Example: {'String'=>{:class=>'Hirb::Helpers::Table', :ancestor=>true, :options=>{:max_width=>180}}}
  module View
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
        if Object.const_defined?(:IRB)
          ::IRB::Irb.class_eval do
            alias :non_hirb_render_output  :output_value
            def output_value #:nodoc:
              Hirb::View.render_output(@context.last_value) || ( Hirb::View.use_pager?(@context.last_value.inspect, true) ?
                Hirb::View.page(@context.last_value.inspect) : non_hirb_render_output)
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

      def toggle_pager
        config[:pager] = !config[:pager]
      end

      def resize
        config.merge! width_and_height_hash
      end
      
      # This is the main method of this class. This method searches for the first formatter it can apply
      # to the object in this order: local block, method option, class option. If a formatter is found it applies it to the object
      # and returns true. Returns false if no formatter found.
      # ==== Options:
      # [:method] Specifies a global (Kernel) method to do the formatting.
      # [:class] Specifies a class to do the formatting, using its render() class method. The render() method's arguments are the output and 
      #          an options hash.
      # [:output_method] Specifies a method or proc to call on output before passing it to a formatter.
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
        @render_method ||= default_render_method
      end

      def reset_render_method
        @render_method = default_render_method
      end

      # Config hash which maps classes to view hashes. View hashes are the same as the options hash of render_output().
      def output_config
        config[:output]
      end

      def output_config=(value)
        @config[:output] = value
      end
      
      # Needs to be called for config changes to take effect. Reloads Hirb::Views classes and registers
      # most recent config changes.
      def reload_config
        current_config = self.config.dup.merge(:output=>output_config)
        load_config(current_config)
      end
      
      # A console version of render_output which takes its same options but allows for some shortcuts.
      # Examples:
      #   console_render_output output, :tree, :type=>:directory
      #   # is the same as:
      #   render_output output, :class=>"Hirb::Helpers::Tree", :options=> {:type=>:directory}
      #
      def console_render_output(*args, &block)
        load_config unless @config
        output = args.shift
        if args[0].is_a?(Symbol) && (view = args.shift)
          symbol_options = find_view(view)
        end
        options = args[-1].is_a?(Hash) ? args[-1] : {}
        options.merge!(symbol_options) if symbol_options
        # iterates over format_output options that aren't :options
        real_options = [:method, :class, :output_method].inject({}) do |h, e|
          h[e] = options.delete(e) if options[e]; h
        end
        render_output(output, real_options.merge(:options=>options), &block)
      end

      #:stopdoc:
      def find_view(name)
        name = name.to_s
        if (view_method = output_config.values.find {|e| e[:method] == name })
          {:method=>view_method[:method]}
        elsif (view_class = Hirb::Helpers.constants.find {|e| e == Util.camelize(name)})
          {:class=>"Hirb::Helpers::#{view_class}"}
        else
          {}
        end
      end

      def format_output(output, options={})
        output_class = determine_output_class(output)
        options = Util.recursive_hash_merge(output_class_options(output_class), options)
        output = options[:output_method] ? (output.is_a?(Array) ? output.map {|e| call_output_method(options[:output_method], e) } : 
          call_output_method(options[:output_method], output) ) : output
        args = [output]
        args << options[:options] if options[:options] && !options[:options].empty?
        if options[:method]
          new_output = send(options[:method],*args)
        elsif options[:class] && (view_class = Util.any_const_get(options[:class]))
          new_output = view_class.render(*args)
        end
        new_output
      end

      def call_output_method(output_method, output)
        output_method.is_a?(Proc) ? output_method.call(output) : output.send(output_method)
      end

      def determine_output_class(output)
        if output.is_a?(Array)
          output[0].class
        else
          output.class
        end
      end

      def load_config(additional_config={})
        self.config = Util.recursive_hash_merge default_config, additional_config
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

      def default_render_method
        lambda {|output|
          use_pager?(output) ? page(output) : puts(output)
        }
      end

      def page(string)
        Hirb::Helpers::Pager.render(string)
      end

      def use_pager?(string_to_page, width_detection=false)
        output_pageable?(string_to_page, width_detection) && Hirb::Helpers::Pager.has_valid_pager?
      end

      def output_pageable?(string_to_page, width_detection=false)
        if width_detection
          config[:pager] && (string_to_page.size > config[:height] * config[:width])
        else
          config[:pager] && (string_to_page.count("\n") > config[:height])
        end
      end

      def default_config
        Hirb::Util.recursive_hash_merge({:output=>default_output_config, :pager=>false}.update(width_and_height_hash), Hirb.config[:view] || {})
      end

      # these environment variables should work for *nix, others should use highline's Highline::SystemExtensions.terminal_size
      def width_and_height_hash
        hash = {}
        hash[:width] = ENV['COLUMNS'] =~ /^\d+$/ ? ENV['COLUMNS'].to_i : 150
        hash[:height] = ENV['LINES'] =~ /^\d+$/ ? ENV['LINES'].to_i : 50
        hash
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
