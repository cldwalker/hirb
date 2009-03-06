current_dir = File.dirname(__FILE__)
$:.unshift(current_dir) unless $:.include?(current_dir) || $:.include?(File.expand_path(current_dir))
require 'hirb/view'
require 'hirb/table'
require 'hirb/table/object'
require 'hirb/table/active_record'
require 'hirb/util'

module Hirb
  class <<self
    def config_file
      File.exists?('config/hirb.yml') ? 'config/hirb.yml' : File.expand_path(File.join("~",".hirb.yml"))
    end

    def read_config_file(file=config_file)
      File.exists?(file) ? YAML::load_file(file) : {}
    end

    def config
      @config ||= read_config_file
    end
  end
end