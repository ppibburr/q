module QSexp
  module Declaration
    def set_modifier(n)
      @modifier = n
    end
    
    def get_access
      if @modifier
        return "public"    if @modifier[:public]
        return "protected" if @modifier[:protected]
        return "private"   if @modifier[:private]            
      end   
    end
    
    def declare_kind
      if @modifier
        return "abstract"    if @modifier[:abstract]
        return "virtual"     if @modifier[:virtual]
        return "override"    if @modifier[:override]            
        return "new"         if @modifier[:replace]
        return "delegate"    if @modifier[:delegate]  
        return "signal"    if @modifier[:signal]               
      end    
    end
    
    def declare_scope
      if @modifier
        return "static"    if @modifier[:static]                
      end 
    end
  end
  
  module GenericsTypeDeclaration
    include ARef
    def self.match? *o
      o[2].args[0].parented nil
      ( o[1].event == :symbol_literal or o[1].args[1].type == :constant) and o[2].args[0].children[0].is_a?(TypeDeclarationRoot)
    rescue
      nil
    end
    
    def build_str(ident = 0)
      "#{" "*ident}" + args[0].build_str + "<" +
      args[1].args[0].children.map do |c| c.type end.join(", ") +
      ">"
    end
    
    def resolved_type
      build_str
    end
  end
end
