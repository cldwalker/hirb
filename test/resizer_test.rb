require File.join(File.dirname(__FILE__), 'test_helper')

module Hirb::Helpers
  class ResizerTest < Test::Unit::TestCase
    test "restrict_field_lengths ensures columns total doesn't exceed max width" do
      @table = Table.new [{:f1=>'f1', :f2=>'2', :f3=>'3', :f4=>'4'}]
      field_lengths = {:f1=>135, :f2=>45, :f3=>4, :f4=>55}
      width = 195

      Table::Resizer.resize!(field_lengths, width)
      field_lengths.values.inject {|a,e| a+=e}.should <= width
    end

    test "restrict_field_lengths sets columns by relative lengths" do
      @table = Hirb::Helpers::Table.new([{:a=>'a', :b=>'b', :c=>'c'}])
      field_lengths = {:a=>30, :b=>30, :c=>40}
      width = 60

      Table::Resizer.resize!(field_lengths, width)
      field_lengths.values.inject {|a,e| a+=e}.should <= width
      field_lengths.values.uniq.size.should_not == 1
    end

    test "restrict_field_lengths sets all columns equal when no long_field and relative methods don't work" do
      @table = Table.new([{:field1=>'f1', :field2=>'f2', :field3=>'f3'}])
      field_lengths = {:field1=>10, :field2=>15, :field3=>100}
      width = 20

      Table::Resizer.resize!(field_lengths, width)
      field_lengths.values.inject {|a,e| a+=e}.should <= width
      field_lengths.values.uniq.size.should == 1
    end
  end
end