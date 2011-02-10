# encoding: utf-8
filename = $*[0]
regex = /(\+(?:-+?\+)+)(\n\s*\|(?:.+?\|)+?)(\n\s*\+(?:-+?\+)+)(?:((?:\n\s*\|(?:.+?\|)+?)+)(\n\s*\+(?:-+?\+)+))?/
data = File.read filename
data.gsub! regex do
  s1, s2, s3, s4, s5 = $1, $2, $3, $4, $5
  s1.sub! '+','┌'
  s1.sub! /\+$/,'┐'
  s1.tr! '-','─'
  s1.tr! '+','┬'

  if s4
    s2.tr! '|','│'
  else
    s2.gsub! /^(\s*)\|/,'\1│'
    s2.gsub! /\|$/,'│'
    s2.tr! '|','╎'
  end

  if s5
    s3.sub! '+','├'
    s3.sub! /\+$/,'┤'
    s3.tr! '-','─'
    s3.tr! '+','┼'
  else
    s3.sub! '+','└'
    s3.sub! /\+$/,'┘'
    s3.tr! '-','─'
    s3.tr! '+','┴'
  end

  if s4
    s4.gsub! /^(\s*)\|/,'\1│'
    s4.gsub! /\|$/,'│'
    s4.tr! '|','╎'
  end

  if s5
    s5.sub! '+','└'
    s5.sub! /\+$/,'┘'
    s5.tr! '-','─'
    s5.tr! '+','┴'
  end

  s1 + s2 + s3 + (s4||'') + (s5||'')
end

File.open(filename, 'w') do |file|
  file.print data
end unless data.empty?
