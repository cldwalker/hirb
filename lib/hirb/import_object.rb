module Hirb
  module ObjectMethods
    # Takes same options as Hirb::View.render_output.
    def view(*args)
      Hirb::Console.render_output(*(args.unshift(self)))
    end
  end
end

Object.send :include, Hirb::ObjectMethods
