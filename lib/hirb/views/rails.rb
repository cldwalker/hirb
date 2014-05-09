module Hirb::Views::Rails #:nodoc:
  def active_record__base_view(obj)
    {:fields=>get_active_record_fields(obj)}
  end

  def get_active_record_fields(obj)
    fields = obj.class.column_names.map {|e| e.to_sym }
    # if query used select
    if obj.attributes.keys.compact.sort != obj.class.column_names.sort
      selected_columns = obj.attributes.keys.compact
      sorted_columns = obj.class.column_names.dup.delete_if {|e| !selected_columns.include?(e) }
      sorted_columns += (selected_columns - sorted_columns)
      fields = sorted_columns.map {|e| e.to_sym}
    end
    fields
  end
end

Hirb::DynamicView.add Hirb::Views::Rails, :helper=>:auto_table
