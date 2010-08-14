# Needed by Hirb::String to handle multibyte characters
$KCODE = 'u' if RUBY_VERSION < '1.9'

require 'hirb/util'
require 'hirb/string'
require 'hirb/formatter' # must come before helpers/auto_table
require 'hirb/dynamic_view'
require 'hirb/helpers'
require 'hirb/views'
require 'hirb/view'
require 'hirb/console'
require 'hirb/pager'
require 'hirb/menu'
require 'hirb/version'

# Most of Hirb's functionality is in Hirb::View.
# For a tutorial  on configuring and creating views see Hirb::View. For a tutorial on dynamic views see Hirb::DynamicView.
#
# == Config Files
# Hirb can have multiple config files defined by config_files(). These config files
# have the following top level keys:
# [*:output*] This hash is used by the formatter object. See Hirb::Formatter.config for its format.
# [*:width*]  Width of the terminal/console. Defaults to Hirb::View::DEFAULT_WIDTH or possibly autodetected when Hirb is enabled.
# [*:height*]  Height of the terminal/console. Defaults to Hirb::View::DEFAULT_HEIGHT or possibly autodetected when Hirb is enabled.
# [*:formatter*] Boolean which determines if the formatter is enabled. Defaults to true.
# [*:pager*] Boolean which determines if the pager is enabled. Defaults to true.
# [*:pager_command*] Command to be used for paging. Command can have options after it i.e. 'less -r'.
#                    Defaults to common pagers i.e. less and more if detected.
# [*:ignore_errors*] Boolean which ignores internal view errors and continues with original view
#                    (i.e. #inspect for irb). Defaults to false.
module Hirb
  class <<self
    attr_accessor :config_files, :config

    # Enables view functionality. See Hirb::View.enable for details.
    def enable(options={}, &block)
      View.enable(options, &block)
    end

    # Disables view functionality. See Hirb::View.disable for details.
    def disable
      View.disable
    end

    # Adds views. See Hirb::View.add for details.
    def add_view(view, options, &block)
      View.add(view, options, &block)
    end

    # Adds views. See Hirb::DynamicView.add for details.
    def add_dynamic_view(view, options, &block)
      DynamicView.add(view, options, &block)
    end

    # Array of config files which are merged sequentially to produce config.
    # Defaults to config/hirb.yml and ~/.hirb_yml
    def config_files
      @config_files ||= default_config_files
    end

    #:stopdoc:
    def default_config_files
      [File.join(Util.find_home, ".hirb.yml")] +
        (File.exists?('config/hirb.yml') ? ['config/hirb.yml'] : [])
    end

    def read_config_file(file=config_file)
      File.exists?(file) ? YAML::load_file(file) : {}
    end

    def config(reload=false)
      if (@config.nil? || reload)
        @config = config_files.inject({}) {|acc,e|
          Util.recursive_hash_merge(acc,read_config_file(e))
        }
      end
      @config
    end
    #:startdoc:
  end
end