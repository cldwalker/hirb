module Hirb
  # Namespace for Helpers defining multiple views in a module i.e. via DynamicView.
  module Views
    module Single #:nodoc:
    end
  end
end
%w{rails orm mongo_db couch_db misc_db}.each {|e| require "hirb/views/#{e}" }