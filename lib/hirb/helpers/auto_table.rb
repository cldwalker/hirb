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
      if obj.class.ancestors.include?(Hirb::Util.any_const_get(klass)) &&
        auto_table.respond_to?("#{meth}_options")
        auto_table.update_config(klass) unless Hirb::View.formatter_config[klass]
        return auto_table.send("#{meth}_options", obj)
      end
    end
  end

  def self.add_module(mod)
    orig_methods = new.option_methods
    include mod
    new_methods = new.option_methods - orig_methods
    new.update_config(new_methods)
  end

  def update_config(meths)
    output_config = meths.inject({}) {|t,e|
      t[method_to_class(e)] = {:class=>self.class, :ancestor=>true}; t
    }
    (Hirb.respond_to?(:enable) && Hirb::View.enabled?) ? Hirb.enable(:output=>output_config) :
      Hirb::Formatter.default_config.merge!(output_config)
  end

  def option_method_classes
    @option_method_classes ||= option_methods.inject({}) {|t,e|
      t[e] = method_to_class(e); t
    }
  end

  def method_to_class(meth)
    Hirb::Util.camelize meth.gsub('__', '/')
  end

  def option_methods
    self.class.instance_methods.select {|e| e.to_s =~ /_options$/ }.map {|e| e.to_s.sub(/_options$/, '') }
  end
end

require 'hirb/helpers/auto_table/orm'
require 'hirb/helpers/auto_table/mongo_db'
require 'hirb/helpers/auto_table/couch_db'