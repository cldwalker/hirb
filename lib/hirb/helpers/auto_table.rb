# This helper wraps around the other table helpers i.e. Hirb::Helpers::Table while
# providing default helper options via Hirb::DynamicView. Using these default options, this
# helper supports views for the following modules/classes:
# ActiveRecord::Base, CouchFoo::Base, CouchPotato::Persistence, CouchRest::ExtendedDocument,
# DBI::Row, DataMapper::Resource, Friendly::Document, MongoMapper::Document, MongoMapper::EmbeddedDocument,
# Mongoid::Document, Ripple::Document, Sequel::Model.
class Hirb::Helpers::AutoTable < Hirb::Helpers::Table
  extend Hirb::DynamicView

  # Takes same options as Hirb::Helpers::Table.render except as noted below.
  #
  # ==== Options:
  # [:table_class] Explicit table class to use for rendering. Defaults to
  #                Hirb::Helpers::ObjectTable if output is not an Array or Hash. Otherwise
  #                defaults to Hirb::Helpers::Table.
  def self.render(output, options={})
    output = Array(output)
    (defaults = dynamic_options(output[0])) && (options = defaults.merge(options))
    klass = options.delete(:table_class) || (
      !(output[0].is_a?(Hash) || output[0].is_a?(Array)) ?
      Hirb::Helpers::ObjectTable : Hirb::Helpers::Table)
    klass.render(output, options)
  end
end