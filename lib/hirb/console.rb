module Hirb
  # This class is meant to be extended to provide methods for use in a console/irb shell.
  # For example:
  #    irb>> extend Hirb::Console
  #    irb>> view 'some string', :class=>Some::String::Formatter
  #    irb>> table [[:row1], [:row2]]
  module Console
    class<<self
      # A console version of render_output() which takes its same options but allows for some shortcuts.
      # The second argument can be an optional symbol which maps to a helper class's nested name. Last argument is an options 
      # hash which is passed to the formatter class except for formatter options: :class, :method and :output_method.
      # Examples:
      #   render_output output, :tree, :type=>:directory
      #   # is the same as:
      #   render_output output, :class=>"Hirb::Helpers::Tree", :options=> {:type=>:directory}
      #
      def render_output(*args)
        View.render_output(*parse_input(*args))
      end

      # Takes same arguments and options as render_output() but returns formatted output instead of rendering it.
      def format_output(*args, &block)
        View.formatter.format_output(*parse_input(*args), &block)
      end

      def parse_input(*args)
        View.load_config unless View.config_loaded?
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
        real_options.merge! :options=>options
        [output, real_options]
      end

      def find_view(name)
        name = name.to_s
        if (view_method = View.formatter.config.values.find {|e| e[:method] == name })
          {:method=>view_method[:method]}
        elsif (view_class = Helpers.constants.find {|e| e == Util.camelize(name)})
          {:class=>"Hirb::Helpers::#{view_class}"}
        else
          {}
        end
      end
    end
    # Renders a table for the given object. Takes same options as Hirb::Helpers::Table.render.
    def table(output, options={})
      Console.render_output(output, options.merge(:class=>"Hirb::Helpers::AutoTable"))
    end
    # Renders any specified view for the given object. Takes same options as Hirb::View.render_output.
    def view(*args)
      Console.render_output(*args)
    end

    def menu(output, options={}, &block)
      Console.format_output(output, options.merge(:class=>"Hirb::Helpers::Menu"), &block)
    end
  end
end
