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

  module QSexp
    module Declaration
      def set_modifier(n)
        @modifier = n
      end
      
      def get_access
        if @modifier
          return "public"    if @modifier[:public]
          return "protected" if @modifier[:protected]
          return "private"   if @modifier[:private]            
        end   
      end
      
      def declare_kind
        if @modifier
          return "abstract"    if @modifier[:abstract]
          return "virtual"     if @modifier[:virtual]
          return "override"    if @modifier[:override]            
          return "new"         if @modifier[:replace]
          return "delegate"    if @modifier[:delegate]      
        end    
      end
      
      def declare_scope
        if @modifier
          return "static"    if @modifier[:static]                
        end 
      end
    end

    module Construct
      include Body
      
      def initialize *o
        super
        @body_stmt = args[2] unless is_a?(StaticConstruct) or is_a?(ClassConstruct)
      end
      
      def build_str ident = 0
        "#{tab = " "*ident}#{type ? type.to_s+" " : ""}construct {\n"+
        body_stmt.build_str(ident+2)+
        "\n#{tab}}"
      end
      
      def type
        return :static if is_a? StaticConstruct
        return :class if is_a? ClassConstruct
        return nil
      end
    end

    module StaticConstruct
      include Construct
      def initialize *o
        super
        @body_stmt = args[4] 
      end 
    end

    module ClassConstruct
      include Construct
      def initialize *o
        super
        @body_stmt = args[1] 
      end  
    end
  end
