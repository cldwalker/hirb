require 'rake'
require 'rake/testtask'
require 'rake/rdoctask'
begin
  require 'rcov/rcovtask'

  Rcov::RcovTask.new do |t|
    t.libs << 'test'
    t.test_files = FileList['test/**/*_test.rb']
    t.rcov_opts = ["-T -x '/Library/Ruby/*'"]
    t.verbose = true
  end
rescue LoadError
  puts "Rcov not available. Install it for rcov-related tasks with: sudo gem install rcov"
end

begin
  require 'jeweler'
  Jeweler::Tasks.new do |s|
    s.name = "hirb"
    s.summary = "A mini view framework for console/irb that's easy to use, even while under its influence."
    s.description = "Hirb currently provides a mini view framework for console applications, designed to improve irb's default output.  Hirb improves console output by providing a smart pager and auto-formatting output. The smart pager detects when an output exceeds a screenful and thus only pages output as needed. Auto-formatting adds a view to an output's class. This is helpful in separating views from content (MVC anyone?). The framework encourages reusing views by letting you package them in classes and associate them with any number of output classes."
    s.email = "gabriel.horner@gmail.com"
    s.homepage = "http://tagaholic.me/hirb/"
    s.authors = ["Gabriel Horner"]
    s.rubyforge_project = 'tagaholic'
    s.has_rdoc = true
    s.extra_rdoc_files = ["README.rdoc", "LICENSE.txt"]
    s.files = FileList["[A-Z]*", "{bin,lib,test}/**/*"]
  end

rescue LoadError
  puts "Jeweler not available. Install it for jeweler-related tasks with: sudo gem install technicalpickles-jeweler -s http://gems.github.com"
end

Rake::TestTask.new do |t|
  t.libs << 'lib'
  t.pattern = 'test/**/*_test.rb'
  t.verbose = false
end

Rake::RDocTask.new do |rdoc|
  rdoc.rdoc_dir = 'rdoc'
  rdoc.title    = 'test'
  rdoc.options << '--line-numbers' << '--inline-source'
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end

task :default => :test
