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
      if (var = args[0]).is_a?(Variables)
        
      else
      
      end
    end
  end
end
