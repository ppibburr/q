module QSexp
  module Ref
    def self.match? *o
      o[0] == :call and o[4].string == "ref!"
    end
    
    def build_str ident = 0
      (" "*ident)+"ref #{args[0].build_str}"
    end
  end
  
  module Out
    def self.match? *o
      o[0] == :call and o[4].string == "out!"
    end
    
    def build_str ident = 0
      (" "*ident)+"out #{args[0].build_str}"
    end
  end
end
