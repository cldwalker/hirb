module Hirb
  module ObjectMethods #:nodoc:
    def view(*args)
      Hirb::View.console_render_output(*(args.unshift(self)))
    end
  end
end

Object.send :include, Hirb::ObjectMethods
