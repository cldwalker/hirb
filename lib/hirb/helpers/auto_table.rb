# Attempts to autodetect the table class the output represents and delegates rendering to it.
class Hirb::Helpers::AutoTable
  # Same options as Hirb::Helpers::Table.render.
  def self.render(output, options={})
    klass = if ((output.is_a?(Array) && output[0].is_a?(ActiveRecord::Base)) or output.is_a?(ActiveRecord::Base) rescue false)
      Hirb::Helpers::ActiveRecordTable
    elsif options[:fields]
      Hirb::Helpers::ObjectTable
    else
      Hirb::Helpers::Table
    end
    klass.render(output, options)
  end
end