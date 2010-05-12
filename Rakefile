require 'rake'
begin
  require 'rcov/rcovtask'

  Rcov::RcovTask.new do |t|
    t.libs << 'test'
    t.test_files = FileList['test/**/*_test.rb']
    t.rcov_opts = ["-T -x '/Library/Ruby/*'"]
    t.verbose = true
  end
rescue LoadError
end

def gemspec
  @gemspec ||= begin
    file = File.expand_path('../hirb.gemspec', __FILE__)
    eval(File.read(file), binding, file)
  end
end

desc "Build the gem"
task :gem=>:gemspec do
  sh "gem build hirb.gemspec"
end

desc "Install the gem locally"
task :install => :gem do
  sh %{gem install #{gemspec.name}-#{gemspec.version}}
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

# begin
#   require 'rake/gempackagetask'
# rescue LoadError
#   task(:gem) { $stderr.puts '`gem install rake` to package gems' }
# else
#   Rake::GemPackageTask.new(gemspec) do |pkg|
#     pkg.gem_spec = gemspec
#   end
#   task :gem => :gemspec
# end

# desc "install the gem locally"
# task :install => :package do
#   sh %{gem install pkg/#{gemspec.name}-#{gemspec.version}}
# end