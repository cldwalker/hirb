module Hirb
  module Display
    class<<self
      attr_accessor :config
      def enable
        ::IRB::Irb.class_eval do
          alias :non_hirb_output_value  :output_value
          def output_value
            Hirb::Display.output_value(@context.last_value) || non_hirb_output_value
          end
        end
      end
      
      def disable
        ::IRB::Irb.class_eval do
          alias :output_value :non_hirb_output_value
        end
      end
      
      def output_value(output)
        if (formatted_output = format_output(output))
          display_output(formatted_output)
          true
        else
          false
        end
      end
      
      def display_output(formatted_output)
        puts formatted_output
      end
      
      def format_output(output)
        output_class = determine_output_class(output)
        if (display_method = output_class_config(output_class)[:method])
          new_output = send(display_method, output)
        elsif (display_class = output_class_config(output_class)[:class]) && (display_class = Util.any_const_get(display_class))
          args = output_class_config(output_class)[:args] || []
          new_output = display_class.run(output, *args)
        end
        new_output
      end
      
      def config=(value); @config = value; @output_class_config = nil; end

      def output_class_config(output_class)
        @output_class_config ||= {}
        @output_class_config[output_class] ||= 
          begin
            output_ancestors_with_config = output_class.ancestors.map {|e| e.to_s}.select {|e| config.has_key?(e)}
            @output_class_config[output_class] = output_ancestors_with_config.reverse.inject({}) {|h, klass|
              h.update(config[klass])
            }
          end
        @output_class_config[output_class]
      end
      
      def determine_output_class(output)
        if output.is_a?(Array)
    			output[0].class
    		else
    			output.class
    		end
    	end      
  	end	
  end
end