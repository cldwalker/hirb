# -*- encoding : utf-8 -*-
class Hirb::Helpers::UnicodeTable < Hirb::Helpers::Table
  CHARS = {
    :top    => {:left => '┌', :center => '┬', :right => '┐', :horizontal => '─', :vertical => {:outside => '│', :inside => '│'} },
    :middle => {:left => '├', :center => '┼', :right => '┤', :horizontal => '─'},
    :bottom => {:left => '└', :center => '┴', :right => '┘', :horizontal => '─', :vertical => {:outside => '│', :inside => '╎'} },
  }

  def self.render(rows, options={})
    new(rows, options).render
  end
end
