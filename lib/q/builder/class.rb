module QSexp
  module Class
    attr_reader :super_class, :implements, :generics
    include Body
    
    def name
      return @name if generics.empty?
      @name + "<" + generics.map do |g| g.build_str end.join(", ") + ">"
    end
    
    def initialize *o
      @implements = nil
      super
      
      @generics = []
      
      case args[0].event
      when :const_ref
        @name = args[0].build_str
      else
        raise
      end
      
      if args[1]
        case args[1].event
        when :aref
          # Superclass with implements
       
          # superclass
          @super_class = args[1].args[0].args[0].string
     
          # implements
          @implements = args[1].args[1].build_str
        
        when :array
          # implements
          @implements = args[1].build_str.gsub(/^\{/,'').gsub(/\}$/,'')
        when :var_ref
          # superclass
          raise "#{line}: Invalid inheritance" unless args[1].args[0].type == :constant
          @super_class = args[1].build_str
        when :const_path_ref
          @super_class = args[1].build_str
        
        when :hash
          @struct = true
        else
          raise "#{line}: Invalid inheritance"
        end
      end
      
      @body_stmt = args[2]
    end
    
    def is_struct?
      !!@struct
    end
    
    def get_type
      return :struct if is_struct?
      return :enum   if is_enum?
      return :class      
    end
    
    def define_struct ident
      args[1].args[0].args[0].map.each do |c|
        (" "*ident) + c.args[1].build_str() + " " + c.args[0].build_str().gsub(":",'')+";"
      end.join("\n")
    end
    
    def build_str ident = 0
      "\n#{" "*ident}public #{get_type} #{name}#{super_class ? " : #{super_class}" : ""}#{implements ? (super_class ? ", " : " : ")+implements : ""} {\n"+
      "#{is_struct? ? define_struct(ident+2)+"\n" : ""}"+
      super(ident)+
      "\n#{" "*ident}}"
    end
  end
  
  module ClassGenericsDeclaration
    def self.match? *o
      o[1].event == :"@ident" and o[1].string == "generics"
    end
  
    def initialize *o
      super
      on_parented do |p|
        unless p.get_scope.is_a?(ClassScope)  
          QSexp::compile_error line, "generics keyword outside of class declaration."  
        end
        
        p.parent.parent.generics << self
        i = p.children.index(self)
        
        def (p.children[i] = "").marked_no_semicolon?
          true
        end
      end
    end
    
    def build_str ident = 0
      args[1].build_str
    end
  end
end
