require File.join(File.dirname(__FILE__), 'test_helper')

module Hirb
  class HelperViewTest < Test::Unit::TestCase
    def output_expects(output, expects)
      Helpers::ObjectTable.expects(:render).with(output, expects)
      Helpers::AutoTable.render(output)
    end

    context "add" do
      before(:all) { View.load_config }

      test "raises error if no :views or :view option" do
        assert_raises(ArgumentError) {
          Hirb.add :helper=>:table
        }.message.should =~ /:view.*required/
      end

      test "raises error if no :helper option" do
        assert_raises(ArgumentError) {
          Hirb.add :view=>'Blah'
        }.message.should =~ /:helper.*required/
      end

      test "raises error if :helper option not a helper_view module" do
        assert_raises(ArgumentError) {
          Hirb.add(:view=>'Blah', :helper=>:table) {|obj| }
        }.message.should =~ /:helper.*must/
      end

      test "raises error if :views option is not a module" do
        assert_raises(ArgumentError) {
          Hirb.add :views=>'Blah', :helper=>:auto_table
        }.message.should =~ /:views.*must/
      end

      test "merges with default config if :view option doesn't have a block" do
        Hirb.add :view=>'Blah', :helper=>:tree
        Formatter.default_config['Blah'].should == {:class=>Hirb::Helpers::Tree}
      end

      test "adds a view with :view option" do
        Hirb.add(:view=>"Date", :helper=>:auto_table) do |obj|
          {:fields=>obj.class::DAYNAMES}
        end
        output_expects [Date.new], :fields=>Date::DAYNAMES
      end

      test "when adding a second :view option overrides the first one" do
        Hirb.add(:view=>"Date", :helper=>:auto_table) do |obj|
          {:fields=>obj.class::DAYNAMES}
        end
        Hirb.add(:view=>"Date", :helper=>:auto_table) do |obj|
          {:fields=>[:blah]}
        end
        output_expects [Date.new], :fields=>[:blah]
      end
    end

    context "helper_view" do
      def define_view(mod_name= :Blah, &block)
        mod = Views.const_set(mod_name, Module.new)
        mod_block = block_given? ? block : lambda {|obj| {:fields=>obj.class::DAYNAMES}}
        mod.send(:define_method, :date_view, mod_block)
        Hirb.add :views=>mod, :helper=>:auto_table
      end

      before(:all) { View.load_config }
      before(:each) { Formatter.default_config = {} }
      after(:each) { Views.send(:remove_const, :Blah) }
      after(:all) { reset_config}

      test "sets a view's options" do
        define_view
        output_expects [Date.new], :fields=>Date::DAYNAMES
      end

      test "does override existing formatter default_config" do
        Formatter.default_config["Date"] = {:class=>Helpers::Table}
        define_view
        Formatter.default_config["Date"].should == {:class=>Hirb::Helpers::AutoTable, :ancestor=>true}
      end

      test "raises a readable error when error occurs in a view" do
        define_view {|obj| raise 'blah' }
        assert_raises(RuntimeError) {
          Helpers::AutoTable.render([Date.new])
        }.message.should =~ /'Date'.*date_view.*\nblah/
      end

      test "another view can reuse an old view's options" do
        define_view
        define_view(:Blah2) do |obj|
          {:fields=>obj.class::DAYNAMES + ['blah']}
        end
        output_expects [Date.new], :fields=>(Date::DAYNAMES + ['blah'])
      end
    end
  end
end
