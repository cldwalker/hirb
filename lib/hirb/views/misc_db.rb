module Hirb::Views::MiscDb #:nodoc:
  def friendly__document_view(obj)
    {:fields=>obj.class.attributes.keys - [:id]}
  end

  def ripple__document_view(obj)
    {:fields=>obj.class.properties.keys}
  end

  def d_b_i__row_view(obj)
    {:fields=>obj.column_names, :table_class=>Hirb::Helpers::Table}
  end
end

Hirb::DynamicView.add Hirb::Views::MiscDb, :helper=>:auto_table