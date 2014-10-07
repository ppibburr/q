module QSexp
  module Body
    attr_reader :body_stmt
    attr_accessor :scope
    def initialize *o
      if is_a?(QSexp::Class)
        @scope = ClassScope.new(self)
      elsif is_a?(Namespace);
        @scope = NamespaceScope.new(self)
      elsif is_a?(Program);
        @scope = ProgramScope.new(self)
      else
        @scope = Scope.new(self)
      end
      
      super
    end
    
    def assign item
      case (n=item.args[1]).event
      when :aref
        n.args
      end
    end
    
    def declare
    
    end
    
    def build_str ident = 0
      @body_stmt.build_str(ident+(self.class.ancestors[1] == Program ? 0 : 2))
    end
  end
end
