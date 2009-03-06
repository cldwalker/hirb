module Hirb
  module Helper
  end
end
%w{table object_table active_record_table auto_table}.each do |e|
  require "hirb/helper/#{e}"
end