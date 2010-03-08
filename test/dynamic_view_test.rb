require File.join(File.dirname(__FILE__), 'test_helper')

module Hirb
  class DynamicViewTest < Test::Unit::TestCase
    def output_expects(output, expects)
      Helpers::ObjectTable.expects(:render).with(output, expects)
      Helpers::AutoTable.render(output)
    end
    after(:all) { Formatter.dynamic_config = {} }

    context "add" do
      before(:all) { View.load_config }

      test "raises error if no :helper option" do
        assert_raises(ArgumentError) {
          Hirb.add_dynamic_view 'Blah', {}
        }.message.should =~ /:helper.*required/
      end

      test "raises error if :helper option not a dynamic_view module" do
        assert_raises(ArgumentError) {
          Hirb.add_dynamic_view('Blah', :helper=>:table) {|obj| }
        }.message.should =~ /:helper.*must/
      end

      test "raises error if views module not a module" do
        assert_raises(ArgumentError) {
          Hirb.add_dynamic_view 'Blah', :helper=>:auto_table
        }.message.should =~ /must be a module/
      end

      test "adds a view with block" do
        Hirb.add_dynamic_view('Date', :helper=>:auto_table) do |obj|
          {:fields=>obj.class::DAYNAMES}
        end
        output_expects [Date.new], :fields=>Date::DAYNAMES
      end

      test "when adding views with a block, second view for same class overrides first one" do
        Hirb.add_dynamic_view('Date', :helper=>:auto_table) do |obj|
          {:fields=>obj.class::DAYNAMES}
        end
        Hirb.add_dynamic_view('Date', :helper=>:auto_table) do |obj|
          {:fields=>[:blah]}
        end
        output_expects [Date.new], :fields=>[:blah]
      end
    end

    context "dynamic_view" do
      def define_view(mod_name= :Blah, &block)
        mod = Views.const_set(mod_name, Module.new)
        mod_block = block_given? ? block : lambda {|obj| {:fields=>obj.class::DAYNAMES}}
        mod.send(:define_method, :date_view, mod_block)
        Hirb.add_dynamic_view mod, :helper=>:auto_table
      end

      before(:all) { View.load_config }
      before(:each) { Formatter.dynamic_config = {} }
      after(:each) { Views.send(:remove_const, :Blah) }
      after(:all) { reset_config }

      test "sets a view's options" do
        define_view
        output_expects [Date.new], :fields=>Date::DAYNAMES
      end

      test "does override existing formatter dynamic_config" do
        Formatter.dynamic_config["Date"] = {:class=>Helpers::Table}
        define_view
        Formatter.dynamic_config["Date"].should == {:class=>Hirb::Helpers::AutoTable, :ancestor=>true}
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
