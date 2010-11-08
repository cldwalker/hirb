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
  s.description = "Hirb provides a mini view framework for console applications and uses it to improve irb's default inspect output. Given an object or array of objects, hirb renders a view based on the object's class and/or ancestry. Hirb offers reusable views in the form of helper classes. The two main helpers, Hirb::Helpers::Table and Hirb::Helpers::Tree, provide several options for generating ascii tables and trees. Using Hirb::Helpers::AutoTable, hirb has useful default views for at least ten popular database gems i.e. Rails' ActiveRecord::Base. Other than views, hirb offers a smart pager and a console menu. The smart pager only pages when the output exceeds the current screen size. The menu is used in conjunction with tables to offer two dimensional menus."
  s.required_rubygems_version = ">= 1.3.5"
  s.rubyforge_project = 'tagaholic'
  s.add_development_dependency 'bacon', '>= 1.1.0'
  s.add_development_dependency 'mocha'
  s.add_development_dependency 'mocha-on-bacon'
  s.add_development_dependency 'bacon-bits'
  s.files = Dir.glob(%w[{lib,test}/**/*.rb bin/* [A-Z]*.{txt,rdoc} ext/**/*.{rb,c} **/deps.rip]) + %w{Rakefile .gemspec}
  s.extra_rdoc_files = ["README.rdoc", "LICENSE.txt"]
  s.license = 'MIT'
end
