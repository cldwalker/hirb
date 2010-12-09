require 'hirb'

module Ripl::Hirb
  class << self
    def enable
      Hirb.enable(Ripl.config[:hirb] || {}) unless Hirb::View.enabled?
    end
  end

  def before_loop
    super
    Ripl::Hirb.enable
  end

  def format_result(result)
    return super if !Hirb::View.enabled?
    Hirb::View.view_or_page_output(result) || super
  end
end

Ripl::Shell.send :include, Ripl::Hirb
Ripl::Hirb.enable if Ripl.instance_variable_get(:@shell) # TODO non hacky way to detect if in ripl session or not
