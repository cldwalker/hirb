module Hirb
  module ObjectMethods
    # Takes same options as Hirb::View.render_output.
    def view(*args)
      Hirb::View.console_render_output(*(args.unshift(self)))
    end
  end
end

Object.send :include, Hirb::ObjectMethods
