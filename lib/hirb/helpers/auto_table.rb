# Detects the table class the output should use and delegates rendering to it.
class Hirb::Helpers::AutoTable
  # Same options as Hirb::Helpers::Table.render.
  def self.render(output, options={})
    options[:_original_class] = output.class
    output = Array(output)
    klass = if (output[0].is_a?(ActiveRecord::Base) rescue false)
      Hirb::Helpers::ActiveRecordTable
    elsif !(output[0].is_a?(Hash) || output[0].is_a?(Array))
      options = (object_table_options(output[0]) || {}).merge options
      Hirb::Helpers::ObjectTable
    else
      Hirb::Helpers::Table
    end
    klass.render(output, options)
  end

  def self.object_table_options(obj)
    auto_table = new
    auto_table.option_method_classes.each do |meth, klass|
      if obj.class.ancestors.include?(Hirb::Util.any_const_get(klass))
        return auto_table.send("#{meth}_options", obj) rescue {}
      end
    end
  end

  def option_method_classes
    @option_method_classes ||= option_methods.inject({}) {|t,e|
      t[e] = Hirb::Util.camelize e.gsub('__', '/') ; t
    }
  end

  def option_methods
    self.class.instance_methods(false).select {|e| e.to_s =~ /_options$/ }.map {|e| e.to_s.sub(/_options$/, '') }
  end

  def mongoid__document_options(obj)
    {:fields=>obj.class.fields.keys}
  end
end