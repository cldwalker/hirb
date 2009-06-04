class Hirb::Helpers::Menu
  def self.render(output, options={})
    options = {:helper_class=>Hirb::Helpers::Table, :prompt=>"Choose #{options[:choose] || ""}: "}.merge(options)
    options[:helper_class] ||= Hirb::Helpers::Table
    $stdout.puts options[:helper_class].render(output, options.merge(:number=>true))
    $stdout.print options[:prompt]
    input = $stdin.gets.chomp.strip
    results = Hirb::Util.choose_from_array(output, input)
    if options[:choose] == :one
      if results.size != 1
        $stdout.puts "Choose one. You chose #{results.size} items."
        return nil
      else
        return results[0]
      end
    end
    results
  end
end