# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{hirb}
  s.version = "0.1.1"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Gabriel Horner"]
  s.date = %q{2009-03-15}
  s.description = %q{A mini view framework for console/irb that's easy to use, even while under its influence.}
  s.email = %q{gabriel.horner@gmail.com}
  s.extra_rdoc_files = ["README.rdoc", "LICENSE.txt"]
  s.files = ["CHANGELOG.rdoc", "LICENSE.txt", "Rakefile", "README.rdoc", "VERSION.yml", "lib/hirb", "lib/hirb/console.rb", "lib/hirb/hash_struct.rb", "lib/hirb/helpers", "lib/hirb/helpers/active_record_table.rb", "lib/hirb/helpers/auto_table.rb", "lib/hirb/helpers/object_table.rb", "lib/hirb/helpers/table.rb", "lib/hirb/helpers.rb", "lib/hirb/import_object.rb", "lib/hirb/util.rb", "lib/hirb/view.rb", "lib/hirb/views", "lib/hirb/views/activerecord_base.rb", "lib/hirb.rb", "test/hirb_test.rb", "test/import_test.rb", "test/table_test.rb", "test/test_helper.rb", "test/util_test.rb", "test/view_test.rb"]
  s.has_rdoc = true
  s.homepage = %q{http://github.com/cldwalker/hirb}
  s.rdoc_options = ["--inline-source", "--charset=UTF-8"]
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.3.1}
  s.summary = %q{A mini view framework for console/irb that's easy to use, even while under its influence.}

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 2

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
    else
    end
  else
  end
end
