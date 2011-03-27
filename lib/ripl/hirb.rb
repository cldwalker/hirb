require 'hirb'

module Ripl::Hirb
  def before_loop
    super
    Hirb.enable(Ripl.config[:hirb] || {})
  end

  def format_result(result)
    return super if !Hirb::View.enabled?
    Hirb::View.view_or_page_output(result) || super
  end
end

Ripl::Shell.include Ripl::Hirb
