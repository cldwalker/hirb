module Hirb::Views::MongoDb #:nodoc:
  def mongoid__document_view(obj)
    {:fields=>['_id'] + obj.class.fields.keys}
  end

  def mongo_mapper__document_view(obj)
    {:fields=>obj.class.column_names}
  end

  def mongo_mapper__embedded_document_view(obj)
    {:fields=>obj.class.column_names}
  end
end

Hirb::DynamicView.add Hirb::Views::MongoDb, :helper=>:auto_table