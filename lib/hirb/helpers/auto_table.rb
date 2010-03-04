# Detects the table class the output should use and delegates rendering to it.
class Hirb::Helpers::AutoTable
  extend Hirb::HelperView

  # Same options as Hirb::Helpers::Table.render.
  def self.render(output, options={})
    output = Array(output)
    klass = if !(output[0].is_a?(Hash) || output[0].is_a?(Array))
      options = (default_options(output[0]) || {}).merge options
      Hirb::Helpers::ObjectTable
    else
      Hirb::Helpers::Table
    end
    klass.render(output, options)
  end
end