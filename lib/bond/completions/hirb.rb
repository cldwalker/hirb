complete(:methods=>%w{Hirb::View.enable Hirb.enable}) {
  %w{config_file output_method output width height formatter pager pager_command}
}
complete(:methods=>%w{Hirb::Helpers::Table.render table}) {
  %w{fields headers max_fields max_width resize number change_fields}+
  %w{filters header_filter filter_any filter_classes vertical all_fields}+
  %w{description escape_special_chars table_class hide_empty unicode grep_fields}
}
complete(:method=>"Hirb::Helpers::Tree.render") {
  %w{type validate indent limit description multi_line_nodes value_method children_method}
}
complete(:methods=>%w{Hirb::Menu.render menu}) {
  %w{helper_class prompt ask directions readline two_d default_field action multi_action} +
    %w{action_object command reopen}
}
