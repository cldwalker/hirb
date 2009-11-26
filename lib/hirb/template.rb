require 'erb'
module Hirb
  module Template
    extend self
    def render(tmpl, obj, options={}, &block)
      tmpl = File.join(template_dir, tmpl) unless tmpl[/^\//] || File.exists?(tmpl)
      erb_render(tmpl, obj, options, &block)
    end

    def erb_render(tmpl, obj, options={}, &block)
      ERB.new(File.read(tmpl)).result(obj.send(:binding))
    end

    def template_dir
      File.dirname(Hirb.config_file) + '/views'
    end
  end
end