module Hirb
  module Util
    extend self
    # Returns a constant like const_get() no matter what namespace it's nested in.
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

    # from Rails ActiveSupport
    def camelize(string)
      string.to_s.gsub(/\/(.?)/) { "::#{$1.upcase}" }.gsub(/(?:^|_)(.)/) { $1.upcase }
    end

    def choose_from_array(array, input, options={})
      options = {:splitter=>","}.merge(options)
      return array if input.strip == '*'
      result = []
      input.split(options[:splitter]).each do |e|
        if e =~ /-|\.\./
          min,max = e.split(/-|\.\./)
          slice_min = min.to_i - 1
          slice_min += options[:offset] if options[:offset]
          result.push(*array.slice(slice_min, max.to_i - min.to_i + 1))
        elsif e =~ /\s*(\d+)\s*/
          index = $1.to_i - 1
          next if index < 0
          index += options[:offset] if options[:offset]
          result.push(array[index])
        end
      end
      return result
    end
  end
end