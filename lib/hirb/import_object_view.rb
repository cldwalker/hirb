module Hirb
  module ObjectMethods
    def view(*args)
      Hirb::View.output_value(*(args.unshift(self)))
    end
  end
end

Object.send :include, Hirb::ObjectMethods