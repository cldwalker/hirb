require File.join(File.dirname(__FILE__), 'test_helper')

describe "DynamicView" do
  def output_expects(output, expects)
    Helpers::ObjectTable.expects(:render).with(output, expects)
    Helpers::AutoTable.render(output)
  end

  describe "add" do
    before_all { View.load_config }

    it "raises error if no :helper option" do
      lambda { Hirb.add_dynamic_view 'Blah', {} }.should.raise(ArgumentError).
        message.should =~ /:helper.*required/
    end

    it "raises error if :helper option not a dynamic_view module" do
      lambda { Hirb.add_dynamic_view('Blah', :helper=>:table) {|obj| } }.
        should.raise(ArgumentError).message.should =~ /:helper.*must/
    end

    it "raises error if views module not a module" do
      lambda { Hirb.add_dynamic_view 'Blah', :helper=>:auto_table }.should.raise(ArgumentError).
        message.should =~ /must be a module/
    end

    it "adds a view with block" do
      Hirb.add_dynamic_view('Date', :helper=>:auto_table) do |obj|
        {:fields=>obj.class::DAYNAMES}
      end
      output_expects [Date.new], :fields=>Date::DAYNAMES
    end

    it "when adding views with a block, second view for same class overrides first one" do
      Hirb.add_dynamic_view('Date', :helper=>:auto_table) do |obj|
        {:fields=>obj.class::DAYNAMES}
      end
      Hirb.add_dynamic_view('Date', :helper=>:auto_table) do |obj|
        {:fields=>[:blah]}
      end
      output_expects [Date.new], :fields=>[:blah]
    end
  end

  it "class_to_method and method_to_class convert to each other" do
    ["DBI::Row", "Hirb::View"].each do |e|
      Helpers::AutoTable.method_to_class(DynamicView.class_to_method(e).downcase).should == e
    end
  end

  it "class_to_method converts correctly" do
    DynamicView.class_to_method("DBI::Row").should == 'd_b_i__row_view'
  end

  describe "dynamic_view" do
    def define_view(mod_name= :Blah, &block)
      mod = Views.const_set(mod_name, Module.new)
      mod_block = block_given? ? block : lambda {|obj| {:fields=>obj.class::DAYNAMES}}
      mod.send(:define_method, :date_view, mod_block)
      Hirb.add_dynamic_view mod, :helper=>:auto_table
    end

    before_all { View.load_config }
    before { Formatter.dynamic_config = {} }
    after { Views.send(:remove_const, :Blah) }

    it "sets a view's options" do
      define_view
      output_expects [Date.new], :fields=>Date::DAYNAMES
    end

    it "does override existing formatter dynamic_config" do
      Formatter.dynamic_config["Date"] = {:class=>Helpers::Table}
      define_view
      Formatter.dynamic_config["Date"].should == {:class=>Hirb::Helpers::AutoTable, :ancestor=>true}
    end

    it "raises a readable error when error occurs in a view" do
      define_view {|obj| raise 'blah' }
      lambda { Helpers::AutoTable.render([Date.new]) }.should.raise(RuntimeError).
        message.should =~ /'Date'.*date_view.*\nblah/
    end

    it "another view can reuse an old view's options" do
      define_view
      define_view(:Blah2) do |obj|
        {:fields=>obj.class::DAYNAMES + ['blah']}
      end
      output_expects [Date.new], :fields=>(Date::DAYNAMES + ['blah'])
    end
    after_all { reset_config }
  end
  after_all { Formatter.dynamic_config = {} }
end