module Hirb
  module Helpers #:nodoc:
  end
end
%w{table object_table active_record_table auto_table tree parent_child_tree vertical_table}.each do |e|
  require "hirb/helpers/#{e}"
end