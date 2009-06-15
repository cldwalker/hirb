class Hirb::Helpers::Menu
  def self.render(output, options={})
    options = {:helper_class=>Hirb::Helpers::AutoTable, :prompt=>"Choose #{options[:choose] || ""}: ", :ask=>true}.merge(options)
    if output.size == 1 && !options[:ask]
      yield(output) if output.size > 0 and block_given?
      return output
    end
    puts options[:helper_class].render(output, options.merge(:number=>true))
    print options[:prompt]
    input = $stdin.gets.chomp.strip
    results = Hirb::Util.choose_from_array(output, input)
    if options[:choose] == :one
      if results.size != 1
        puts "Choose one. You chose #{results.size} items."
        return nil
      else
        return results[0]
      end
    end
    yield(results) if results.size > 0 and block_given?
    results
  end
end