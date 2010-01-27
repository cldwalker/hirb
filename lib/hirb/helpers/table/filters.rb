class Hirb::Helpers::Table
  # Contains filter methods used by :filters option. To define a custom filter, simply open this module and create a method
  # that take one argument, the value you will be filtering.
  module Filters
    extend self
    def comma_join(arr) #:nodoc:
      arr.join(', ')
    end
  end
end