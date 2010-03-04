module Hirb
  module Helpers #:nodoc:
    @helper_classes ||= {}
    def self.helper_class(klass)
      @helper_classes[klass.to_s] ||= begin
        if (helper_class = constants.find {|e| e.to_s == Util.camelize(klass.to_s)})
          klass = "Hirb::Helpers::#{helper_class}"
        end
        Util.any_const_get(klass)
      end
    end
  end
end

%w{table object_table auto_table tree parent_child_tree vertical_table}.each do |e|
  require "hirb/helpers/#{e}"
end