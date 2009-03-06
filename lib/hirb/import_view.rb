module Hirb
  module Console
    def table(output, options={})
      Hirb::View.output_value(output, options.merge(:class=>"Hirb::Helpers::AutoTable"))
    end

    def view(*args)
      Hirb::View.output_value(*args)
    end
  end
end

self.extend Hirb::Console