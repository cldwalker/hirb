require 'console'

module Hirb::Unicode
  def size(string)
    ::Console.display_width(string)
  end

  def slice(string, start, finish)
    ::Console.display_slice(string, start, finish)
  end

  def ljust(string, desired_length)
    leftover = desired_length - size(string)
    leftover > 0 ? string + " " * leftover : string
  end

  def rjust(string, desired_length)
    leftover = desired_length - size(string)
    leftover > 0 ? " " * leftover + string : string
  end
end

Hirb::String.extend Hirb::Unicode
