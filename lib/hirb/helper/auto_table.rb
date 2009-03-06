class Hirb::Helper::AutoTable
  def self.render(output, options={})
    klass = if ((output.is_a?(Array) && output[0].is_a?(ActiveRecord::Base)) or output.is_a?(ActiveRecord::Base) rescue false)
      Hirb::Helper::ActiveRecordTable
    elsif options[:fields]
      Hirb::Helper::ObjectTable
    else
      Hirb::Helper::Table
    end
    klass.render(output, options)
  end
end