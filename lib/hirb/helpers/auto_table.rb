# Detects the table class the output should use and delegates rendering to it.
class Hirb::Helpers::AutoTable
  extend Hirb::HelperView

  # Same options as Hirb::Helpers::Table.render.
  def self.render(output, options={})
    output = Array(output)
    (defaults = default_options(output[0])) && (options = defaults.merge options)
    klass = options.delete(:table_class) || (
      !(output[0].is_a?(Hash) || output[0].is_a?(Array)) ?
      Hirb::Helpers::ObjectTable : Hirb::Helpers::Table)
    klass.render(output, options)
  end
end