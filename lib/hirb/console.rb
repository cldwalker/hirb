module Hirb
  module Console
    def table(output, options={})
      Hirb::View.console_render_output(output, options.merge(:class=>"Hirb::Helpers::AutoTable"))
    end

    def view(*args)
      Hirb::View.console_render_output(*args)
    end
  end
end
