module QSexp
  module Namespace
    include Body
    attr_accessor :name, :block
    def initialize *o
      super
      
      on_parented do |p|
        @name = parent.args[0].args[1].args[0].children[0].args[0].build_str
        @body_stmt = parent.args.delete_at(1)
        @body_stmt.parented(self)
        parent.args[0] = self
        @args = []
        @body_stmt.scope = self.scope
        
        pp = p
        until pp.event == :method_add_block
          pp = pp.parent
          break unless pp
        end
        
        raise "namespace no find parent body!" unless pp
        
        pp.mark_no_semicolon true
      end
    end
    
    def build_str ident = 0
     "#{tab=" "*ident}namespace #{name} {\n"+
     @body_stmt.args[1].build_str(ident+2) +
     tab + "}"
    end
  end
end
