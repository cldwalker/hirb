module Hirb
  # This module is meant to be extended to provide methods for use in a console/irb shell.
  # For example:
  #    >> extend Hirb::Console
  #    >> view 'some string', :class=>Some::String::Formatter
  #    >> table [[:row1], [:row2]]
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
        View.load_config unless View.config_loaded?
        View.render_output(output, options.merge(:console=>true))
      end

      # Takes same arguments and options as render_output() but returns formatted output instead of rendering it.
      def format_output(output, options={}, &block)
        View.load_config unless View.config_loaded?
        View.formatter.format_output(output, options.merge(:console=>true), &block)
      end
    end

    # Renders a table for the given object. Takes same options as Hirb::Helpers::Table.render.
    def table(output, options={})
      Console.render_output(output, options.merge(:class=>"Hirb::Helpers::AutoTable"))
    end

    # Renders any specified view for the given object. Takes same options as Hirb::View.render_output.
    def view(output, options={})
      Console.render_output(output, options)
    end

    # Renders a menu given an array using Hirb::Menu.render.
    def menu(output, options={}, &block)
      Console.format_output(output, options.merge(:class=>"Hirb::Menu"), &block)
    end
  end
end
