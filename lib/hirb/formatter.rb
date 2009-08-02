module Hirb
=begin rdoc
  This class is format an output into a string using Hirb::Helpers::*, Hirb::Views::* or any user-created views.
  The formatter object looks for an output's class config in Hirb::Formatter.config and if found applies a helper to the output.

  == Create and Configure Views
  Let's create a simple view and configure it in different ways to be Hash's default view:

  === Setup
    irb>> require 'hirb'
    =>true
    irb>> Hirb.enable
    =>nil
    irb>> require 'yaml'
    =>true

  === Configure As View Method
  A view method is the smallest reuseable view.
    # Create yaml view method
    irb>> def yaml(output); output.to_yaml; end
    =>nil

    # Configure view
    irb>>Hirb::View.format_class Hash, :method=>:yaml
    =>true

    # Hashes now appear as yaml
    irb>>{:a=>1, :b=>{:c=>3}}
    ---
    :a : 1
    :b : 
      :c : 3
    => true

  === Configure As View Class
  A view class is suited for more complex views. View classes can be under any namespace
  and are expected to provide a render method. However, if a class is under the Hirb::Views namespace,
  it will be automatically loaded with no configuration. Something to think about when
  sharing views with others.

    # Create yaml view class
    irb>> class Hirb::Views::Hash; def self.render(output, options={}); output.to_yaml; end ;end
    =>nil
    # Just reload since no configuration is necessary
    irb>>Hirb::View.formatter.reload

    # Hashes now appear as yaml ...

  Although the Hirb::Views namespace is great for quick classes that just plug and play, you
  often want view classes that can be reused with multiple outputs. For this case, it's recommended to
  use the Hirb::Helpers namespace.

    # Create yaml view class
    irb>> class Hirb::Helpers::Yaml; def self.render(output, options={}); output.to_yaml; end ;end
    =>nil

    # Configure view and reload it
    irb>>Hirb::View.format_class Hash, :class=>"Hirb::Helpers::Yaml"
    =>true

    # Hashes now appear as yaml ...

    == Configure At Startup
    Once you know what views are associated with what output classes, you can configure
    them at startup by passing Hirb.enable an options hash:
      # In .irbrc
      require 'hirb'
      # View class needs to come before enable()
      class Hirb::Helpers::Yaml; def self.render(output, options={}); output.to_yaml; end ;end
      Hirb.enable :output=>{"Hash"=>{:class=>"Hirb::Helpers::Yaml"}}

    Or by creating a config file at config/hirb.yml or ~/.hirb.yml:
      # The config file for the yaml example would look like:
      # ---
      # :output :
      #   Hash :
      #    :class : Hirb::Helpers::Yaml

      # In .irbrc
      require 'hirb'
      # View class needs to come before enable()
      class Hirb::Helpers::Yaml; def self.render(output, options={}); output.to_yaml; end ;end
      Hirb.enable
=end 
  
  class Formatter
    def initialize(additional_config={})
      @klass_config = {}
      @config = Util.recursive_hash_merge default_config, additional_config || {}
    end

    # A hash of Ruby class strings mapped to helper config hashes. A helper config hash must have at least a :method, :output_method
    # or :class option for a helper to be applied to an output. A helper config hash has the following keys:
    # [:method] Specifies a global (Kernel) method to do the formatting.
    # [:class] Specifies a class to do the formatting, using its render() class method. If a symbol it's converted to a corresponding
    #          Hirb::Helpers::* class if it exists.
    # [:output_method] Specifies a method or proc to call on output before passing it to a helper. If the output is an array, it's applied
    #                  to every element in the array.
    # [:options] Options to pass the helper method or class.
    # [:ancestor] Boolean which when true causes subclasses of the output class to inherit its config. This doesn't effect the current 
    #             output class. Defaults to false. This is used by ActiveRecord classes.
    # 
    #   Examples:
    #     {'WWW::Delicious::Element'=>{:class=>'Hirb::Helpers::ObjectTable', :ancestor=>true, :options=>{:max_width=>180}}}
    #     {'Date'=>{:class=>:auto_table, :ancestor=>true}}
    def config
      @config
    end

    # Sets the helper config for the given output class.
    def format_class(klass, helper_config)
      @klass_config.delete(klass)
      @config[klass.to_s] = helper_config
      true
    end

    # Reloads autodetected Hirb::Views
    def reload
      @config = Util.recursive_hash_merge default_config, @config
    end

    # This is the main method of this class. The formatter looks for the first helper in its config for the given output class.
    # If a helper is found, the output is converted by the helper into a string and returned. If not, nil is returned. The options
    # this class takes are a helper config hash as described in config. These options will be merged with any existing helper config hash
    # an output class has in config. Any block given is passed along to a helper class.
    def format_output(output, options={}, &block)
      output_class = determine_output_class(output)
      options = parse_console_options(options) if options.delete(:console)
      options = Util.recursive_hash_merge(klass_config(output_class), options)
      output = options[:output_method] ? (output.is_a?(Array) ? output.map {|e| call_output_method(options[:output_method], e) } : 
        call_output_method(options[:output_method], output) ) : output
      args = [output]
      args << options[:options] if options[:options] && !options[:options].empty?
      if options[:method]
        new_output = send(options[:method],*args)
      elsif options[:class] && (helper_class = determine_helper_class(options[:class]))
        new_output = helper_class.render(*args, &block)
      elsif options[:output_method]
        new_output = output
      end
      new_output
    end

    #:stopdoc:
    def parse_console_options(options) #:nodoc:
      real_options = [:method, :class, :output_method].inject({}) do |h, e|
        h[e] = options.delete(e) if options[e]; h
      end
      real_options.merge! :options=>options
      real_options
    end

    def determine_helper_class(klass)
      if klass.is_a?(Symbol) && (helper_class = Helpers.constants.find {|e| e == Util.camelize(klass.to_s)})
        klass = "Hirb::Helpers::#{helper_class}"
      end
      Util.any_const_get(klass)
    end

    def determine_output_class(output)
      if output.is_a?(Array)
        output[0].class
      else
        output.class
      end
    end

    def call_output_method(output_method, output)
      output_method.is_a?(Proc) ? output_method.call(output) : output.send(output_method)
    end

    # Internal view options built from user-defined ones. Options are built by recursively merging options from oldest
    # ancestors to the most recent ones.
    def klass_config(output_class)
      @klass_config[output_class] ||= begin
        output_ancestors_with_config = output_class.ancestors.map {|e| e.to_s}.select {|e| @config.has_key?(e)}
        @klass_config[output_class] = output_ancestors_with_config.reverse.inject({}) {|h, klass|
          (klass == output_class.to_s || @config[klass][:ancestor]) ? Util.recursive_hash_merge(h, @config[klass]) : h
        }
      end
    end

    def reset_klass_config
      @klass_config = {}
    end

    def default_config
      Views.constants.inject({}) {|h,e|
        output_class = e.to_s.gsub("_", "::")
        if (views_class = Views.const_get(e)) && views_class.respond_to?(:render)
          default_options = views_class.respond_to?(:default_options) ? views_class.default_options : {}
          h[output_class] = default_options.merge({:class=>"Hirb::Views::#{e}"})
        end
        h
      }
    end
    #:startdoc:
  end
end