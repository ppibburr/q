module QSexp  
  module Assignment
    include Declaration
    def initialize *o
      super
      
      on_parented do |p|
        until p.respond_to? :assign
          p = p.parent
        end
        p.assign self
      end
    end
    
    def build_str ident=0
       case args[1].event
       when :aref
         case args[1].args[0].event
         when :symbol_literal
           if !args[1].args[1]
             type = :declare_array
           elsif (z=args[1].args[1].args[0].children.length) == 1  
             type = :set_array_length
           else
             type = :set_declare_array
           end
           
           return build_type_array(type,ident)
         end
         
       when :symbol_literal
         return declare_type(ident)
         
       when :method_add_block
         type = args[1].args[1].delegate_type
         type = type ? type.to_s+" " : ""
         d = args[1].build_str(args[1].is_a?(MethodAddBlock) ? ident : 0)
        
         if (is_local?() and new_local?()) or !is_local?
           # Full declaration with assignment
           return "\n#{" "*ident}#{[:class, :namespace].index(get_scope_type()) ? declare_scope() : ""}#{type}"+args[0].build_str(0) + " = "+ d
         else
           # Assignment
           return "\n#{" "*ident}"+args[0].build_str(0) + " = "+ d 
         end
       end unless args[1].is_a?(GenericsTypeDeclaration)
       
       if args[1].is_a?(GenericsTypeDeclaration)
         return declare_type(ident) 
       end
       
      
      if is_local?() and !new_local?()
        "#{" "*ident}"+args[0].build_str(0) + " = "+ args[1].build_str(args[1].is_a?(MethodAddBlock) ? ident : 0)
      elsif !is_local?()
        if args[1].is_a?(String)
          type = get_scope_type != :generic ? "string " : ""
        else
          type = get_scope_type != :generic ? (args[1].is_a?(Single) ? args[1].resolved_type.to_s+" " : "#{args[1].resolved_type} "): ""
        end
        
        d = args[1].build_str(args[1].is_a?(MethodAddBlock) ? ident : 0)
        
        "#{" "*ident}#{[:class, :namespace].index(get_scope_type()) ? declare_scope() : ""}#{type}"+args[0].build_str(0) + " = "+ d
      elsif is_local?() and new_local?()
        get_scope.new_local(args[0].args[0].string, args[0].args[0].type)
        return "#{" "*ident}var "+args[0].build_str(0) + " = "+ args[1].build_str(args[1].is_a?(MethodAddBlock) ? ident : 0)
      end
    end
    
    def declare_type(ident)
      "#{" "*ident}#{get_access} #{args[1].build_str(0)} "+args[0].build_str(0)
    end
    
    def is_local?
      args[0].event == :var_field and args[0].args[0].type == :local
    end
    
    def new_local?
      !get_scope().lvars[args[0].args[0].string]
    end
    
    def build_type_array type, ident=0
      bool = is_local?
    
      typed = "#{args[1].args[0].build_str}"
      case type
      when :declare_array
        return "#{" "*ident}#{[:class, :namespace].index(get_scope_type()) ? declare_scope() : ""}"+typed+"[] #{args[0].build_str(0)}"
      when :set_array_length
        val = "[#{args[1].args[1].args[0].build_str(0).gsub("\n",'').gsub(";",'')}]"
        if bool and new_local?
          get_scope.new_local(args[0].args[0].string, args[0].args[0].type)
          x = "var "
        elsif bool
          x = ""
        else
          x = "#{[:class, :namespace].index(get_scope_type()) ? declare_scope() : ""}"+typed+"[] "
        end
        
        return "#{" "*ident}#{x}#{args[0].build_str(0)} = new #{typed}"+val  
            
      when :set_declare_array
        val = "{#{args[1].args[1].args[0].build_str(0).gsub("\n",", ").gsub(/\, $/,'').gsub(";",'')}}"
        if bool and new_local?
          get_scope.new_local(args[0].args[0].string, args[0].args[0].type)
          x = "var "
        elsif bool
          x = ""
        else
          x = "#{[:class, :namespace].index(get_scope_type()) ? declare_scope() : ""}"+typed+"[] "
        end      
         return "#{" "*ident}#{x}#{args[0].build_str(0)} = "+val
      end   
    end
    
    def declare_scope
      return "" if is_local?
    
      super or "#{[:static, :class].index(n=args[0].args[0].type) ? "#{get_access()} #{n} " : (args[0].args[0].type == :instance) ? "public " : ""}"
    end
    
    def get_access
      r = super
      return r if r
      
      args[0].args[0].type == :instance ? "public" : "protected"
    end
  end
end
