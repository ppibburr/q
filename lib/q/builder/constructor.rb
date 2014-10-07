module QSexp
  module Constructor
    include Defs
    def self.match? *o
      o[3].string == "new" or o[3].string =~ /^new_/
    end
    
    def initialize *o
      super
      set_explicit_return "" 
    end
    
    
    def parented p
      super
      
      pp = self
      
      until pp.is_a?(QSexp::Class)
        pp = pp.parent
        break unless pp
      end
      unless pp
        puts "COMPILE ERROR - #{line}: Constructor declared outside of Class definition"
        exit(127)
      end
      n = @symbol.to_s
      n = "" if n == "new"
      n = ".#{n.gsub(/^new\_/,'')}" if n =~ /^new/
      @symbol = pp.name+"#{n}"
    end
    
    def declare_scope
      ""
    end
    
    def declare_kind
      ""
    end
  end
end
