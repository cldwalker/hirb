module Hirb
  module ObjectMethods
    def view(*args)
      Hirb::View.console_render_output(*(args.unshift(self)))
    end
  end
end

Object.send :include, Hirb::ObjectMethods
