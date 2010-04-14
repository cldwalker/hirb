require File.join(File.dirname(__FILE__), 'test_helper')

describe "Resizer" do
  def table(options)
    @table = Helpers::Table.new [options[:field_lengths].keys.inject({}) {|t,e| t[e] = '1'; t}]
    @table.field_lengths = options[:field_lengths]
    @table.width = options[:width]
    @table.max_fields = options[:max_fields] if options[:max_fields]
    @width, @field_lengths = @table.width, @table.field_lengths
    @table
  end

  it "resize ensures columns total doesn't exceed max width" do
    table :field_lengths=>{:f1=>135, :f2=>45, :f3=>4, :f4=>55}, :width=>195
    Helpers::Table::Resizer.resize!(@table)
    @field_lengths.values.inject {|a,e| a+=e}.should <= @width
  end

  it "resize sets columns by relative lengths" do
    table :field_lengths=>{:a=>30, :b=>30, :c=>40}, :width=>60
    Helpers::Table::Resizer.resize!(@table)
    @field_lengths.values.inject {|a,e| a+=e}.should <= @width
    @field_lengths.values.uniq.size.should.not == 1
  end

  it "resize sets all columns roughly equal when adusting long fields don't work" do
    table :field_lengths=>{:field1=>10, :field2=>15, :field3=>100}, :width=>20
    Helpers::Table::Resizer.resize!(@table)
    @field_lengths.values.inject {|a,e| a+=e}.should <= @width
    @field_lengths.values.each {|e| e.should <= 4 }
  end

  describe "add_extra_width and max_fields" do
    def table_and_resize(options={})
      defaults = {:field_lengths=>{:f1=>135, :f2=>30, :f3=>4, :f4=>100}, :width=>195, :max_fields=>{:f1=>80, :f4=>30} }
      @table = table defaults.merge(options)
      # repeated from table since instance variables aren't copied b/n contexts
      @width, @field_lengths = @table.width, @table.field_lengths
      Helpers::Table::Resizer.resize! @table
    end

    it "doesn't add to already maxed out field" do
      table_and_resize
      @field_lengths[:f3].should == 4
    end

    it "restricted before adding width" do
      table_and_resize
      @field_lengths[:f4].should <= 30
    end

    it "adds to restricted field" do
      table_and_resize
      @field_lengths[:f1].should <= 80
    end

    it "adds to unrestricted field" do
      table_and_resize :field_lengths=>{:f1=>135, :f2=>70, :f3=>4, :f4=>100}
      @field_lengths[:f2].should == 70
    end
  end
end