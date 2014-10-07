module QSexp
  module Def
    attr_accessor :return_type, :symbol, :parameters
    include Body
    include Declaration
    def initialize *o
      super
      
      unless is_a?(Defs)
        @symbol    = args[0].build_str.to_sym
        @body_stmt = args[2]
      
        @parameters = args[1]
      
        if args[2].args[0].children[0].event == :symbol_literal
          set_explicit_return(args[2].args[0].children.shift)
        end
      else
        @symbol    = args[2].build_str.to_sym
        @body_stmt = args[4]
      
        @parameters = args[3]
          
        if args[4].args[0].children[0].event == :symbol_literal
          set_explicit_return(args[4].args[0].children.shift)
        end
      end
    end
    
    def set_explicit_return item
      @return_type = item.build_str.to_sym
    end
    
    def build_str(ident=0)
      "\n#{" "*ident}#{get_access()} #{declare_scope()} #{declare_kind()} #{return_type || "void"} #{symbol}("+parameters.build_str+")"+
      (delegate? ? ";" : " {\n#{super(ident)+"\n#{" "*ident}}"}")
    end
    
    def delegate?
      @modifier and @modifier[:delegate]
    end
    
    def get_access
      super or "public"
    end
    
    def get_scope
      parent ? parent.get_scope : scope
    end
    
    def declare_scope
      super or (is_a?(Defs) ? "static" : nil)
    end
    
    def declare_kind
      n = nil
      if (n = super)
      elsif get_scope_type != :class
        n = ""
      elsif declare_scope != "static"
        n = "virtual" 
      else
        n = ""
      end

      return n
    end
  end

  module Defs
    include Def
  end
end
