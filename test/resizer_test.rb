require File.join(File.dirname(__FILE__), 'test_helper')

class Hirb::Helpers::Table
  class ResizerTest < Test::Unit::TestCase
    def table(options)
      @table = Hirb::Helpers::Table.new [options[:field_lengths].keys.inject({}) {|t,e| t[e] = '1'; t}]
      @table.field_lengths = options[:field_lengths]
      @table.width = options[:width]
      @table.max_fields = options[:max_fields] if options[:max_fields]
      @width, @field_lengths = @table.width, @table.field_lengths
    end

    test "resize ensures columns total doesn't exceed max width" do
      table :field_lengths=>{:f1=>135, :f2=>45, :f3=>4, :f4=>55}, :width=>195
      Resizer.resize!(@table)
      @field_lengths.values.inject {|a,e| a+=e}.should <= @width
    end

    test "resize sets columns by relative lengths" do
      table :field_lengths=>{:a=>30, :b=>30, :c=>40}, :width=>60
      Resizer.resize!(@table)
      @field_lengths.values.inject {|a,e| a+=e}.should <= @width
      @field_lengths.values.uniq.size.should_not == 1
    end

    test "resize sets all columns roughly equal when adusting long fields don't work" do
      table :field_lengths=>{:field1=>10, :field2=>15, :field3=>100}, :width=>20
      Resizer.resize!(@table)
      @field_lengths.values.inject {|a,e| a+=e}.should <= @width
      @field_lengths.values.each {|e| e.should <= 4 }
    end

    context "add_extra_width and max_fields" do
      def table_and_resize(options={})
        defaults = {:field_lengths=>{:f1=>135, :f2=>30, :f3=>4, :f4=>100}, :width=>195, :max_fields=>{:f1=>80, :f4=>30} }
        table defaults.merge(options)
        Resizer.resize! @table
      end

      test "doesn't add to already maxed out field" do
        table_and_resize
        @field_lengths[:f3].should == 4
      end

      test "restricted before adding width" do
        table_and_resize
        @field_lengths[:f4].should <= 30
      end

      test "adds to restricted field" do
        table_and_resize
        @field_lengths[:f1].should <= 80
      end

      test "adds to unrestricted field" do
        table_and_resize :field_lengths=>{:f1=>135, :f2=>70, :f3=>4, :f4=>100}
        @field_lengths[:f2].should == 70
      end
    end
  end
end