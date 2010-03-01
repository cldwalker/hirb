class Hirb::Helpers::AutoTable
  module CouchDb
    def default_couch(obj)
      {:fields=>([:_id] + obj.class.properties.map {|e| e.name }) }  
    end

    alias_method :couch_rest__extended_document_options, :default_couch
    alias_method :couch_foo__base_options, :default_couch
    alias_method :couch_potato__persistence_options, :default_couch
  end

  add_module CouchDb
end