module Hirb::Views::ORM
  def data_mapper__resource_options(obj)
    { :fields=>obj.class.properties.map {|e| e.name } }
  end

  def sequel__model_options(obj)
    {:fields=>obj.class.columns}
  end
end

Hirb::Helpers::AutoTable.add_module Hirb::Views::ORM