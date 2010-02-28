class Hirb::Helpers::AutoTable
  module ORM
    def data_mapper__resource_options(obj)
      { :fields=>obj.class.properties.map {|e| e.name } }
    end
  end

  add_module ORM
end