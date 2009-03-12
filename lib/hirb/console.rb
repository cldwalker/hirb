module Hirb
  # This class is meant to be extended to provide methods for use in a console/irb shell.
  # For example:
  #    irb>> extend Hirb::Console
  #    irb>> view 'some string', :class=>Some::String::Formatter
  #    irb>> table [[:row1], [:row2]]
  module Console
    # Renders a table for the given object. Takes same options as Hirb::Helpers::Table.render.
    def table(output, options={})
      Hirb::View.console_render_output(output, options.merge(:class=>"Hirb::Helpers::AutoTable"))
    end
    # Renders any specified view for the given object. Takes same options as Hirb::View.render_output.
    def view(*args)
      Hirb::View.console_render_output(*args)
    end
  end
end
