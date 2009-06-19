module Hirb
  # This module is meant to be extended to provide methods for use in a console/irb shell.
  # For example:
  #    irb>> extend Hirb::Console
  #    irb>> view 'some string', :class=>Some::String::Formatter
  #    irb>> table [[:row1], [:row2]]
  module Console
    class<<self
      # A console version of render_output() which takes its same options but allows for shorthand. All options are passed to
      # the helper except for the formatter options. Formatter options are :class, :method and :output_method.
      # Examples:
      #   render_output output, :class=>:tree :type=>:directory
      #   # is the same as:
      #   render_output output, :class=>:tree, :options=> {:type=>:directory}
      #
      def render_output(output, options={})
        View.render_output(*parse_input(output, options))
      end

      # Takes same arguments and options as render_output() but returns formatted output instead of rendering it.
      def format_output(output, options={}, &block)
        View.formatter.format_output(*parse_input(output, options), &block)
      end

      def parse_input(output, options)
        View.load_config unless View.config_loaded?
        real_options = [:method, :class, :output_method].inject({}) do |h, e|
          h[e] = options.delete(e) if options[e]; h
        end
        real_options.merge! :options=>options
        [output, real_options]
      end
    end

    # Renders a table for the given object. Takes same options as Hirb::Helpers::Table.render.
    def table(output, options={})
      Console.render_output(output, options.merge(:class=>"Hirb::Helpers::AutoTable"))
    end
    # Renders any specified view for the given object. Takes same options as Hirb::View.render_output.
    def view(output, options={})
      Console.render_output(*args)
    end

    def menu(output, options={}, &block)
      Console.format_output(output, options.merge(:class=>"Hirb::Menu"), &block)
    end
  end
end
