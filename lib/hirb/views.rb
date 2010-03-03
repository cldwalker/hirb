module Hirb
  # Namespace for Helpers using HelperView to have class-specific views
  module Views
  end
end
%w{rails orm mongo_db couch_db}.each {|e| require "hirb/views/#{e}" }