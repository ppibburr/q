module QSexp
  module Construct
    include Body
    
    def initialize *o
      super
      @body_stmt = args[2] unless is_a?(StaticConstruct) or is_a?(ClassConstruct)
    end
    
    def build_str ident = 0
      "#{tab = " "*ident}#{type ? type.to_s+" " : ""}construct {\n"+
      body_stmt.build_str(ident+2)+
      "\n#{tab}}"
    end
    
    def type
      return :static if is_a? StaticConstruct
      return :class if is_a? ClassConstruct
      return nil
    end
  end

  module StaticConstruct
    include Construct
    def initialize *o
      super
      @body_stmt = args[4] 
    end 
  end

  module ClassConstruct
    include Construct
    def initialize *o
      super
      @body_stmt = args[1] 
    end  
  end
end
