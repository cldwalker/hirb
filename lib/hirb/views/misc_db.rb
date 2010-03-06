module Hirb::Views::MiscDb
  def friendly__document_options(obj)
    {:fields=>obj.class.attributes.keys - [:id]}
  end

  def ripple__document_options(obj)
    {:fields=>obj.class.properties.keys}
  end

  def d_b_i__row_options(obj)
    {:fields=>obj.column_names, :table_class=>Hirb::Helpers::Table}
  end
end

Hirb::HelperView.add :views=>Hirb::Views::MiscDb, :helper=>:auto_table