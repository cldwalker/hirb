module Hirb::Views::MongoDb
  def mongoid__document_options(obj)
    {:fields=>obj.class.fields.keys + ['_id']}
  end

  def mongo_mapper__document_options(obj)
    {:fields=>obj.class.column_names}
  end

  def mongo_mapper__embedded_document_options(obj)
    {:fields=>obj.class.column_names}
  end
end

Hirb::Helpers::AutoTable.add_module Hirb::Views::MongoDb