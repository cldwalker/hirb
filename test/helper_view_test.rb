require File.join(File.dirname(__FILE__), 'test_helper')

module Hirb
  class HelperViewTest < Test::Unit::TestCase
    context "helper_view" do
      def define_view(mod_name= :Blah, &block)
        mod = Views.const_set(mod_name, Module.new)
        mod_block = block_given? ? block : lambda {|obj| {:fields=>obj.class::DAYNAMES}}
        mod.send(:define_method, :date_options, mod_block)
        Helpers::AutoTable.add_module mod
      end
      before(:all) { View.load_config }
      before(:each) { Formatter.default_config = {} }
      after(:each) { Views.send(:remove_const, :Blah) }
      after(:all) { reset_config}

      def output_expects(output, expects)
        Helpers::ObjectTable.expects(:render).with(output, expects)
        Helpers::AutoTable.render(output)
      end

      test "sets a view's options" do
        define_view
        output_expects [Date.new], :fields=>Date::DAYNAMES
      end

      test "doesn't override existing formatter default_config" do
        Formatter.default_config["Date"] = {:class=>Helpers::Table}
        define_view
        Formatter.default_config["Date"].should == {:class=>Helpers::Table}
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
