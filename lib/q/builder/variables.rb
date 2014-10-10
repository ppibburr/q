module QSexp
  module Variables
    def build_str ident=0;
      q = case args[0].type
      when :static
        args[0].string.gsub("@@",'')
      when :class
        args[0].string.gsub("$",'') 
      when :instance  
        args[0].string.gsub("@",get_scope_type() == :class ? "" : "this.")   
      else
        args[0].string    
      end
      "#{" "*ident}#{q == "super" ? "base" : (q == "self" ? "this" : q)}"
    end
    
    def type
      args[0].type
    end
    
    def name
      build_str
    end
  end

  module VarRef
    include Variables
  end

  module VarField
    include Variables
  end
end
