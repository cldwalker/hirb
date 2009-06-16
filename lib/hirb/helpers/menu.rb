# Note this class should only be used via Hirb::Console. It *can't* currently be used as other helper classes are in automated views.
class Hirb::Helpers::Menu
  # Menu which asks to select from the given array and returns the selected menu items as an array. See Hirb::Util.chosen_from_array()
  # for the syntax for specifying selections.
  #
  # ==== Options:
  # [:helper_class]  Helper class to render menu. Helper class is expected to implement numbering given a :number option.
  #                  To use a very basic menu, set this to false. Defaults to Hirb::Helpers::AutoTable.
  # [:prompt]  String for menu prompt. Defaults to "Choose: ".
  # [:validate_one] Validates that only one item in array is chosen and returns just that item. Default is false.
  # [:ask] Always ask for input, even if there is only one choice. Default is true.
  # Examples:
  #     extend Hirb::Console
  #     menu([1,2,3], :validate_one=>true)
  #     menu([1,2,3], :helper_class=>Hirb::Helpers::Table)
  def self.render(output, options={})
    default_options = {:helper_class=>Hirb::Helpers::AutoTable, :prompt=>"Choose #{options[:validate_one] ? 'one' : ''}: ", :ask=>true}
    options = default_options.merge(options)
    output = [output] unless output.is_a?(Array)
    chosen = choose_from_menu(output, options)
    yield(chosen) if block_given? && chosen.is_a?(Array) && chosen.size > 0
    chosen
  end

  def self.choose_from_menu(output, options) #:nodoc:
    return output if output.size == 1 && !options[:ask]
    if (helper_class = Hirb::Util.any_const_get(options[:helper_class]))
      puts helper_class.render(output, options.merge(:number=>true))
    else
      output.each_with_index {|e,i| puts "#{i+1}: #{e}" }
    end
    print options[:prompt]
    input = $stdin.gets.chomp.strip
    chosen = Hirb::Util.choose_from_array(output, input)
    if options[:validate_one]
      if chosen.size != 1
        $stderr.puts "Choose one. You chose #{chosen.size} items."
        return nil
      else
        return chosen[0]
      end
    end
    chosen
  end
end