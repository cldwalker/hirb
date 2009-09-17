current_dir = File.dirname(__FILE__)
$:.unshift(current_dir) unless $:.include?(current_dir) || $:.include?(File.expand_path(current_dir))

# Needed by Hirb::String to handle multibyte characters
$KCODE = 'u' if RUBY_VERSION < '1.9'

require 'hirb/util'
require 'hirb/string'
require 'hirb/hash_struct'
require 'hirb/helpers'
require 'hirb/view'
require 'hirb/views/activerecord_base'
require 'hirb/console'
require 'hirb/formatter'
require 'hirb/pager'
require 'hirb/menu'

# Most of Hirb's functionality currently resides in Hirb::View.
# For an in-depth tutorial on creating and configuring views see Hirb::Formatter.
# Hirb has an optional yaml config file defined by config_file(). This config file
# has the following top level keys:
# [:output] This hash is used by the formatter object. See Hirb::Formatter.config for its format.
# [:width]  Width of the terminal/console. Defaults to DEFAULT_WIDTH or possibly autodetected when Hirb is enabled.
# [:height]  Height of the terminal/console. Defaults to DEFAULT_HEIGHT or possibly autodetected when Hirb is enabled.
# [:formatter] Boolean which determines if the formatter is enabled. Defaults to true.
# [:pager] Boolean which determines if the pager is enabled. Defaults to true.
# [:pager_command] Command to be used for paging. Command can have options after it i.e. 'less -r'.
#                  Defaults to common pagers i.e. less and more if detected.
#

module Hirb
  class <<self
    # Enables view functionality. See Hirb::View.enable for details.
    def enable(options={}, &block)
      View.enable(options, &block)
    end

    # Disables view functionality. See Hirb::View.disable for details.
    def disable
      View.disable
    end
    # Default is config/hirb.yml or ~/hirb.yml in that order.
    def config_file
      @config_file ||= File.exists?('config/hirb.yml') ? 'config/hirb.yml' :
        File.expand_path(File.join(ENV["HOME"] || ".", ".hirb.yml"))
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