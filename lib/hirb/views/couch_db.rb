module Hirb::Views::CouchDb #:nodoc:
  def default_couch(obj)
    {:fields=>([:_id] + obj.class.properties.map {|e| e.name }) }
  end

  alias_method :couch_rest__extended_document_view, :default_couch
  alias_method :couch_foo__base_view, :default_couch
  alias_method :couch_potato__persistence_view, :default_couch
end

Hirb::DynamicView.add Hirb::Views::CouchDb, :helper=>:auto_table