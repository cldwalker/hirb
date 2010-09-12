module Hirb
  # Group of handy utility functions used throughout Hirb.
  module Util
    extend self
    # Returns a constant like Module#const_get no matter what namespace it's nested in.
    # Returns nil if the constant is not found.
    def any_const_get(name)
      return name if name.is_a?(Module)
      begin
        klass = Object
        name.split('::').each {|e|
          klass = klass.const_get(e)
        }
        klass
      rescue
         nil
      end
    end

    # Recursively merge hash1 with hash2.
    def recursive_hash_merge(hash1, hash2)
      hash1.merge(hash2) {|k,o,n| (o.is_a?(Hash)) ? recursive_hash_merge(o,n) : n}
    end

    # From Rails ActiveSupport, converting undescored lowercase to camel uppercase.
    def camelize(string)
      string.to_s.gsub(/\/(.?)/) { "::#{$1.upcase}" }.gsub(/(?:^|_)(.)/) { $1.upcase }
    end

    # Used by Hirb::Menu to select items from an array. Array counting starts at 1. Ranges of numbers are specified with a '-' or '..'.
    # Multiple ranges can be comma delimited. Anything that isn't a valid number is ignored. All elements can be returned with a '*'.
    # Examples:
    #    1-3,5-6 -> [1,2,3,5,6]
    #    *   -> all elements in array
    #    ''  -> [] 
    def choose_from_array(array, input, options={})
      options = {:splitter=>","}.merge(options)
      return array if input.strip == '*'
      result = []
      input.split(options[:splitter]).each do |e|
        if e =~ /-|\.\./
          min,max = e.split(/-|\.\./)
          slice_min = min.to_i - 1
          result.push(*array.slice(slice_min, max.to_i - min.to_i + 1))
        elsif e =~ /\s*(\d+)\s*/
          index = $1.to_i - 1
          next if index < 0
          result.push(array[index]) if array[index]
        end
      end
      result
    end

    # Determines if a shell command exists by searching for it in ENV['PATH'].
    def command_exists?(command)
      ENV['PATH'].split(File::PATH_SEPARATOR).any? {|d| File.exists? File.join(d, command) }
    end

    # Returns [width, height] of terminal when detected, nil if not detected.
    # Think of this as a simpler version of Highline's Highline::SystemExtensions.terminal_size()
    def detect_terminal_size
      if (ENV['COLUMNS'] =~ /^\d+$/) && (ENV['LINES'] =~ /^\d+$/)
        [ENV['COLUMNS'].to_i, ENV['LINES'].to_i]
      elsif (RUBY_PLATFORM =~ /java/ || (!STDIN.tty? && ENV['TERM'])) && command_exists?('tput')
        [`tput cols`.to_i, `tput lines`.to_i]
      elsif STDIN.tty? && command_exists?('stty')
        `stty size`.scan(/\d+/).map { |s| s.to_i }.reverse
      else
        nil
      end
    rescue
      nil
    end

    # Captures STDOUT of anything run in its block and returns it as string.
    def capture_stdout(&block)
      original_stdout = $stdout
      $stdout = fake = StringIO.new
      begin
        yield
      ensure
        $stdout = original_stdout
      end
      fake.string
    end

    # From Rubygems, determine a user's home.
    def find_home
      ['HOME', 'USERPROFILE'].each {|e| return ENV[e] if ENV[e] }
      return "#{ENV['HOMEDRIVE']}#{ENV['HOMEPATH']}" if ENV['HOMEDRIVE'] && ENV['HOMEPATH']
      File.expand_path("~")
    rescue
      File::ALT_SEPARATOR ? "C:/" : "/"
    end
  end
end
