# Produces a table like this:
# 
#    | name            |  commands  |  gems               |  library_type |
#    |---------------- | ---------- | ------------------- | --------------|
#    | core/object     |  6         |                     |  file         |
#    | dir             |  7         |                     |  file         |
#    | file            |  5         |                     |  file         |
#    | readme          |  4         |                     |  file         |
#    | system          |  4         |                     |  file         |
#    | readmemd        |  1         |                     |  file         |
#    | github          |  9         |                     |  file         |
#    | reload_library  |  1         |                     |  file         |
#    | system_misc     |  11        |                     |  file         |
#    | tree            |  4         |                     |  file         |
#    | core/class      |  4         |                     |  file         |
#    | core/module     |  3         |                     |  file         |
#    | console         |  3         |                     |  file         |
#    | core            |  6         |                     |  module       |
#    | web_core        |  5         |                     |  module       |
#    | ansi            |  3         |  ansi,win32console  |  file         |
#
#    NOTE: This does not currently include column alignment:
#    |  left   | center  | right |
#    | :------ | :-----: | ----: |
#
#    NOTE: This does not actually output markdown (or HTML), but rather
#    formats the table in a way which is compatible with markdown tables, and
#    hence compatible with markdown to HTML table conversion.
#
class Hirb::Helpers::MarkdownTable < Hirb::Helpers::Table
  CHARS = {
    :top => {:left => '', :center => '', :right => '', :horizontal => '',
      :vertical => {:outside => '|', :inside => ' | '} },
    :middle => {:left => '|', :center => ' | ', :right => '|', :horizontal => '-'},
    :bottom => {:left => '', :center => '', :right => '', :horizontal => '',
      :vertical => {:outside => '|', :inside => ' | '} }
  }

  # Renders a markdown-compatible table
  def self.render(rows, options={})
    new(rows, options).render
  end
end
