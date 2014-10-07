module QSexp
  module Parameters
    class Parameter
      attr_reader :type, :name
      def initialize name, type = nil
        @name = name.build_str
        if type
          @type = type.build_str
          if type.event == :aref 
           # @type << "[]"
          end
        end
      end
      
      def build_str ident=0
        "#{" "*ident}#{type}#{type ? " " : ""}#{name.gsub(":","")}"
      end
    end
    
    attr_accessor :typed_parameters, :untyped_parameters
    def initialize *o
      super 
      @typed_parameters   = args[4].map do |a| Parameter.new(*a) end if args[4]
      @untyped_parameters = args[0].map do |a| Parameter.new(*a) end if args[0]
    end
    
    def build_str ident=0
      s = "#{" "*ident}"
      s << untyped_parameters.map do |prm|  prm.build_str end.join(", ") if untyped_parameters 
      s << typed_parameters.map do |prm|  prm.build_str end.join(", ") if typed_parameters         
      s
    end
  end
end
