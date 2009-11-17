# Detects the table class the output should use and delegates rendering to it.
class Hirb::Helpers::AutoTable
  # Same options as Hirb::Helpers::Table.render.
  def self.render(output, options={})
    options[:_original_class] = output.class
    output = Array(output)
    klass = if (output[0].is_a?(ActiveRecord::Base) rescue false)
      Hirb::Helpers::ActiveRecordTable
    elsif !(output[0].is_a?(Hash) || output[0].is_a?(Array))
      Hirb::Helpers::ObjectTable
    else
      Hirb::Helpers::Table
    end
    klass.render(output, options)
  end
end
