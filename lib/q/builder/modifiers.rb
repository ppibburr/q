module QSexp
  module MemberModifier
    FLAGS = [
      :abstract,
      :virtual,
      :override,
      :replace,
      :delegate,
      :static
    ]
    
    include VCall
    
    attr_reader :previous
    def prepend n
      (@previous ||= [])
      
      n.previous.each do |q|
        previous << q
      end
      
      previous.insert 0, n
    end
    
    
    
    def initialize *o
      super *o
      
      @previous = []
      
      on_parented do |p|
        if :generic == p.get_scope_type
          raise "wrong scope for member modifier"
        end

        raise "cannot use member modifier here" unless p.is_a?(Statements)
        
        i = p.children.index(self)
        
        n =  p.children[i+1]
        
        if n.is_a?(MemberModifier)
          n.prepend self
          
          next
        end
        
        unless n.is_a?(Assignment) or n.is_a?(Def) or n.is_a?(MemberModifier)
          raise "Member Modifier has invalid target: #{n.event}"
        end
        
        n.set_modifier(self)
      end
    end
    
    def build_str ident=0
      ""
    end
    
    def [] k
      (previous.find do |q| q.args[0].string.to_sym == k end) or args[0].string.to_sym == k 
    end
  end
end
