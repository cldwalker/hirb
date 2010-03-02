require File.join(File.dirname(__FILE__), 'test_helper')

module Hirb
  class HelperViewTest < Test::Unit::TestCase
    context "helper_view" do
      before(:all) { View.load_config }
      before(:each) {
        class ::Hirb::Helpers::AutoTable
          module Blah
            def date_options(obj)
              {:fields=>obj.class::DAYNAMES}
            end
          end
          add_module Blah
        end
      }
      after(:each) { Hirb::Helpers::AutoTable.send(:remove_const, :Blah) }
      after(:all) { reset_config}

      def output_expects(output, expects)
        Helpers::ObjectTable.expects(:render).with(output, expects)
        Helpers::AutoTable.render(output)
      end

      test "sets options" do
        output_expects [Date.new], :fields=>Date::DAYNAMES
      end

      test "overrides a view's options" do
        class ::Hirb::Helpers::AutoTable
          module Blah2
            def date_options(obj)
              {:fields=>obj.class::DAYNAMES + ['blah']}
            end
          end
          add_module Blah2
        end
        output_expects [Date.new], :fields=>(Date::DAYNAMES + ['blah'])
      end
    end
  end
end
