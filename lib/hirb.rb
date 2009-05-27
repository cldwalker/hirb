current_dir = File.dirname(__FILE__)
$:.unshift(current_dir) unless $:.include?(current_dir) || $:.include?(File.expand_path(current_dir))
require 'hirb/util'
require 'hirb/hash_struct'
require 'hirb/helpers'
require 'hirb/view'
require 'hirb/views/activerecord_base'
require 'hirb/console'

# Most of Hirb's functionality currently resides in Hirb::View.
# Hirb has an optional yaml config file defined by config_file. This config file
# has the following top level keys:
# [:view] See Hirb::View for the value of this entry.
module Hirb
  class <<self
    # Default is config/hirb.yml or ~/hirb.yml in that order.
    def config_file
      @config_file ||= File.exists?('config/hirb.yml') ? 'config/hirb.yml' : File.expand_path(File.join(ENV["HOME"],".hirb.yml"))
    end

    #:stopdoc:
    def config_file=(value)
      @config_file = value
    end

    def read_config_file(file=config_file)
      File.exists?(file) ? YAML::load_file(file) : {}
    end

    def config(reload=false)
      @config = (@config.nil? || reload) ? read_config_file : @config
    end
    #:startdoc:
  end
end