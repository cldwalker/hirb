require File.join(File.dirname(__FILE__), 'test_helper')

module Hirb
  class HelperViewTest < Test::Unit::TestCase
    context "helper_view" do
      before(:all) {
        class ::Hirb::Helpers::AutoTable
          module Blah
            def date_options(obj)
              {:fields=>obj.class::DAYNAMES}
            end
          end
          add_module Blah
        end
      }

      test "sets options" do
        View.load_config
        output = [Date.new]
        Helpers::ObjectTable.expects(:render).with(output, :fields=>Date::DAYNAMES)
        Helpers::AutoTable.render(output)
        reset_config
      end
    end
  end
end
