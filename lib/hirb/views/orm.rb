module Hirb::Views::ORM #:nodoc:
  def data_mapper__resource_view(obj)
    {:fields=>obj.class.properties.map {|e| e.name }}
  end

  def sequel__model_view(obj)
    {:fields=>obj.class.columns}
  end
end

Hirb::DynamicView.add Hirb::Views::ORM, :helper=>:auto_table