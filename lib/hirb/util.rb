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

    def choose_from_array(array, range,splitter=',',offset=nil)
      result = []
      for r in range.split(splitter)
      if r =~ /-/
        min,max = r.split('-')
        slice_min = min.to_i - 1
        slice_min += offset if offset
        result.push(*array.slice(slice_min, max.to_i - min.to_i + 1))
      else
        index = r.to_i - 1
        index += offset if offset
        result.push(array[index])
      end
      end
      return result
    end
  end
end