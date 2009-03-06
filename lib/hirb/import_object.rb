module Hirb
  module ObjectMethods
    def view(*args)
      Hirb::View.console_output_value(*(args.unshift(self)))
    end
  end
end

Object.send :include, Hirb::ObjectMethods