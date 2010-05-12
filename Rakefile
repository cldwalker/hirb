require 'rake'
require 'fileutils'

def gemspec
  @gemspec ||= begin
    file = File.expand_path('../hirb.gemspec', __FILE__)
    eval(File.read(file), binding, file)
  end
end

desc "Build the gem"
task :gem=>:gemspec do
  sh "gem build #{gemspec.name}.gemspec"
  FileUtils.mkdir_p 'pkg'
  FileUtils.mv "#{gemspec.name}-#{gemspec.version}.gem", 'pkg'
end

desc "Install the gem locally"
task :install => :gem do
  sh %{gem install pkg/#{gemspec.name}-#{gemspec.version}}
end

desc "Generate the gemspec"
task :generate do
  puts gemspec.to_ruby
end

desc "Validate the gemspec"
task :gemspec do
  gemspec.validate
end

desc 'Run specs with unit test style output'
task :test do |t|
  sh 'bacon -q -Ilib test/*_test.rb'
end

task :default => :test