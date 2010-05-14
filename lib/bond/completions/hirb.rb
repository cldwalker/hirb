complete(:methods=>%w{Hirb::View.enable Hirb.enable}) {
  %w{config_file output_method output width height formatter pager pager_command}
}
complete(:method=>'Hirb::Helpers::Table.render') {
  %w{fields headers max_fields max_width resize number change_fields}+
  %w{filters header_filter filter_any filter_classes vertical all_fields}+
  %w{description escape_special_chars table_class hide_empty}
}
complete(:method=>"Hirb::Helpers::Tree.render") {
  %w{type validate indent limit description multi_line_nodes value_method children_method}
}
complete(:method=>"Hirb::Menu.render") {
  %w{helper_class prompt ask directions readline two_d default_field action multi_action action_object command}
}