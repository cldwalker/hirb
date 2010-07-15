# -*- encoding: utf-8 -*-
require 'rubygems' unless Object.const_defined?(:Gem)
require File.dirname(__FILE__) + "/lib/hirb/version"
 
Gem::Specification.new do |s|
  s.name        = "hirb"
  s.version     = Hirb::VERSION
  s.authors     = ["Gabriel Horner"]
  s.email       = "gabriel.horner@gmail.com"
  s.homepage    = "http://tagaholic.me/hirb/"
  s.summary     = "A mini view framework for console/irb that's easy to use, even while under its influence."
  s.description = "Hirb currently provides a mini view framework for console applications, designed to improve irb's default output.  Hirb improves console output by providing a smart pager and auto-formatting output. The smart pager detects when an output exceeds a screenful and thus only pages output as needed. Auto-formatting adds a view to an output's class. This is helpful in separating views from content (MVC anyone?). The framework encourages reusing views by letting you package them in classes and associate them with any number of output classes." 
  s.required_rubygems_version = ">= 1.3.6"
  s.rubyforge_project = 'tagaholic'
  s.add_development_dependency 'bacon'
  s.add_development_dependency 'mocha'
  s.add_development_dependency 'mocha-on-bacon'
  s.files = Dir.glob(%w[{lib,test}/**/*.rb bin/* [A-Z]*.{txt,rdoc} ext/**/*.{rb,c}]) + %w{Rakefile gemspec}
  s.extra_rdoc_files = ["README.rdoc", "LICENSE.txt"]
end