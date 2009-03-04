# modified from http://gist.github.com/72234

# items are activerecord objects, fields are any record attributes
def active_record_table(items, fields=[])
  items = [items] unless items.is_a?(Array)
  fields = items.first.attribute_names unless fields.any?
  fields = fields.map {|e| e.to_sym}
  fields.unshift(fields.delete(:id)) if fields.include?(:id)
  object_table(items, fields)
end

# items is an array of ruby objects, fields are attributes of the given objects
def object_table(items, fields, options={})
  item_hashes = items.inject([]) {|t,item|
    t << fields.inject({}) {|h,f| h[f] = item.send(f).to_s; h}
  }
  hash_table(item_hashes, options.update(:fields=>fields))
end

# prints out an array of hashes
def hash_table(item_hashes, options={})
  options[:max_total_length] ||= 190
  fields = options[:fields] || item_hashes[0].keys
  return "0 rows in set" if item_hashes.size == 0
  
  if options[:field_lengths]
    field_lengths = options[:field_lengths]
  else
    field_lengths = calculate_field_lengths(item_hashes, fields)
    ensure_safe_field_lengths(field_lengths, options[:max_total_length])
  end
  
  border = '+-' + fields.map {|f| '-' * field_lengths[f] }.join('-+-') + '-+'
  title_row = '| ' + fields.map {|f| sprintf("%-#{field_lengths[f]}s", f.to_s) }.join(' | ') + ' |'
  body = [border, title_row, border]
  
  item_hashes.each do |item|
    row = '| ' + fields.map {|f| sprintf("%-#{field_lengths[f]}s", item[f].slice(0, field_lengths[f])) }.join(' | ') + ' |'
    body << row
  end
 
  body << border
  body << "#{item_hashes.length} rows in set"
  body.join("\n")
end

def ensure_safe_field_lengths(field_lengths, max_total_length)
  fields = field_lengths.keys
  total_length = field_lengths.values.inject {|t,n| t += n}
  if total_length > max_total_length
    average_field_length = total_length / fields.size.to_f
    long_lengths, short_lengths = field_lengths.values.partition {|e| e > average_field_length}
    new_long_field_length = (max_total_length - short_lengths.inject {|t,n| t += n}) / long_lengths.size
    field_lengths.each {|f,length|
      field_lengths[f] = new_long_field_length if length > new_long_field_length
    }
  end
end

def calculate_field_lengths(hash_array, fields=nil)
  return {} if hash_array.empty?
  fields ||= hash_array[0].keys
  # find max length for each field; start with the field names themselves
  field_lengths = Hash[*fields.map {|f| [f, f.to_s.length]}.flatten]
  hash_array.each do |item|
    fields.each do |field|
      # len = item.send(field).to_s.length
      len = item[field].length
      field_lengths[field] = len if len > field_lengths[field]
    end
  end
  field_lengths
end
