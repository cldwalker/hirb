class Hirb::Helpers::AutoTable
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