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
      declare = nil

      if args[1].is_a?(TypeDeclarationRoot) and args[1].is_a?(DeclareArrayType)
        declare = 2
      elsif args[1].is_a?(TypeDeclarationRoot) and args[1].is_a?(DeclareArrayTypeWithAssignment)
        declare = 3
      elsif args[1].is_a?(TypeDeclarationRoot)
        declare = 1
      else
        declare = 0
      end
    
      if (var = args[0]).is_a?(Variables)
        case var.type
        when :local
          return assign_local(ident, declare)
        
        when :static
          return assign_static(ident, declare)
          
        when :class
          return assign_class(ident, declare)
        
        when :instance
          return assign_instance(ident, declare)        
        else
          
        end
      else
        return "#{(" ")*ident}#{args[0].build_str} = #{args[1].build_str}"
      end
    end
    
    def check_do_new_local name, declare
      rt =  resolve_type_for_value(args[1], declare)
    
      if declare >= 1
        QSexp.compile_error(line, "<scope> already contains a definition for `#{name}'") if get_scope[name]
        QSexp.compile_error(line, "Local variable `#{name}' conflicts with a local variable or constant declared in a parent scope") if get_scope[name] and args[1].is_a?(HasBlock)
      
      elsif declare == 0 
        QSexp.compile_error(line, "<scope> already contains a definition for `#{name}'") if rt and get_scope[name] and !rt == get_scope[name]
      end    
    
      if get_scope[name]
        false
      else
        get_scope.new_local name, rt
      end
    end
    
    def resolve_type_for_value v, declare
      if v.is_a?(TypeDeclarationRoot)
        return v.type
      end
      
      return :simple
    end
    
    def assign_local ident, declare
      QSexp.compile_error line, "Local Variable Assignment outside of block." unless [:program, :generic].index(get_scope_type) 
    
      name       = args[0].name
      
      type = check_do_new_local(name, declare)
      
      tab = (" "*ident)
      
      if type and declare == 1
        "#{type} #{name}"      
        
      elsif type and declare == 3
        # `var' array declaration with value
        tab + "var #{name} = new #{type}[] #{args[1].value}"  
      
      elsif type and declare == 2
        # `var' array declaration
        tab + "var #{name} = new #{type}[#{args[1].length}]" 
      
      elsif type == :simple
        # simple `var' declaration
        tab + "var #{name} = #{args[1].build_str}"
        
      elsif !type
        # assignment
        tab + "#{name} = #{args[1].build_str(ident).gsub(Regexp.new("^#{tab}"),'')}"
      end
    end
    
    def assign_static ident, declare
      if declare > 0 and [:program, :generic].index(get_scope_type)
        QSexp.compile_error line, "[static] Field declaration outside of container root body"
      end
      
      name = args[0].build_str
      type = args[1].type if declare > 0
      
      case declare
      when 0
        "#{" "*ident}#{name} = #{args[1].build_str}"
      when 1
        "#{" "*ident}#{get_access(:static)} static #{type} #{name}"
      when 2
        "#{" "*ident}#{get_access(:static)} static #{type}[]#{args[1].length != "" ? " #{name} = new #{type}[#{args[1].length}]" : " #{name}"}"
      when 3
        "#{" "*ident}#{get_access(:static)} static #{type}[] #{name} = new #{type}[] {#{args[1].value}}"
      else
      
      end
    end
    
    def assign_class ident, declare
      if declare > 0 and [:program, :generic].index(get_scope_type)
        QSexp.compile_error line, "[class] Field declaration outside of container root body"
      end
      
      name = args[0].build_str
      type = args[1].type if declare > 0
      
      case declare
      when 0
        "#{" "*ident}#{name} = #{args[1].build_str}"
      when 1
        "#{" "*ident}#{get_access(:class)} class #{type} #{name}"
      when 2
        "#{" "*ident}#{get_access(:class)} class #{type}[]#{args[1].length != "" ? " #{name} = new #{type}[#{args[1].length}]" : " #{name}"}"
      when 3
        "#{" "*ident}#{get_access(:class)} class #{type}[] #{name} = new #{type}[] {#{args[1].value}}"
      else
      
      end
    end    
  
    def assign_instance ident, declare
      if declare > 0 and [:program, :generic].index(get_scope_type)
        QSexp.compile_error line, "[instance] Field declaration outside of container root body"
      end
      
      name = args[0].build_str
      type = args[1].type if declare > 0
      
      case declare
      when 0
        "#{" "*ident}#{name} = #{args[1].build_str}"
      when 1
        "#{" "*ident}#{get_access(:instance)} #{type} #{name}"
      when 2
        "#{" "*ident}#{get_access(:instance)} #{type}[]#{args[1].length != "" ? " #{name} = new #{type}[#{args[1].length}]" : " #{name}"}"
      when 3
        "#{" "*ident}#{get_access(:instance)} #{type}[] #{name} = new #{type}[] {#{args[1].value}}"
      else
      
      end
    end
    
    def get_access kind
      super() || kind == :instance ? "public" : "protected"
    end   
  end
end
