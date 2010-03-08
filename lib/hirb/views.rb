module Hirb
  # Namespace for Helpers using DynamicView to have class-specific views
  module Views
    module Single #:nodoc:
    end
  end
end
%w{rails orm mongo_db couch_db misc_db}.each {|e| require "hirb/views/#{e}" }