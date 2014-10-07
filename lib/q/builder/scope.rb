module QSexp
  class Scope
    attr_accessor :lvars, :item, :type, :parent_scope, :owner
    def initialize owner
      @lvars = {}
      @owner = owner
      if (@parent_scope = owner.get_scope)
        parent_scope.lvars.each_pair do |k, v|
          lvars[k] = v
        end
      end
    end
    
    def new_local fld, type
      @lvars[fld] = type
    end
  end

  class ClassScope < Scope
  end

  class NamespaceScope < Scope
  end

  class ProgramScope < Scope
  end
end
