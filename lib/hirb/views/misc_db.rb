module Hirb::Views::MiscDb
  def friendly__document_options(obj)
    {:fields=>obj.class.attributes.keys - [:id]}
  end

  def ripple__document_options(obj)
    {:fields=>obj.class.properties.keys}
  end
end

Hirb::Helpers::AutoTable.add_module Hirb::Views::MiscDb