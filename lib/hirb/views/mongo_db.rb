module Hirb::Views::MongoDb #:nodoc:
  def mongoid__document_view(obj)
    {:fields=>['_id'] + obj.class.fields.keys}
  end

  def mongo_mapper__document_view(obj)
    fields = obj.class.column_names
    fields.delete('_id') && fields.unshift('_id')
    {:fields=>fields}
  end
  alias_method :mongo_mapper__embedded_document_view, :mongo_mapper__document_view
end

Hirb::DynamicView.add Hirb::Views::MongoDb, :helper=>:auto_table