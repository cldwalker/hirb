module Ripl::Hirb
  def before_loop
    super
    require 'hirb'
    Hirb.enable(Ripl.config[:hirb] || {}) unless Hirb::View.enabled?
  end

  def format_result(result)
    return super if !Hirb::View.enabled?
    Hirb::View.view_or_page_output(result) || super
  end
end

Ripl::Shell.send :include, Ripl::Hirb
