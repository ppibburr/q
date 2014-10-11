module QSexp::Property
  def self.match? *o
    o[0] == :command and o[2].string == "property"
  end
  
  
  attr_reader :type, :name, :body_stmt, :default
  def initialize *o
    super
    
    case args[1].args[0].children.length
    when 3
      # property foo, :type, value
    
      @default = args[1].args[0].children[2].build_str
      @name = args[1].args[0].children[0].build_str
      @type = args[1].args[0].children[1].build_str
    when 1
      # property foo, :type # do ... end
    
      @name = args[1].args[0].children[0].args[0][0].args[0].string.gsub(/\:$/,'') 
      @type = args[1].args[0].children[0].args[0][0].args[1].build_str()       
    else
      QSexp.compile_error line, "Bad arguments for `property'"
    end
    
  
    
    on_parented do |p|
      unless p.get_scope_type == :class
        QSexp.compile_error line, "`property' declaration outside of class root."
      end
    
      if p.is_a? QSexp::MethodAddBlock
        @block_stmt = p.args[1].body_stmt
        @block_stmt.parent.scope.lvars["default"] = :simple
      
      
        def p.build_str ident = 0
          args[0].build_str ident
        end
      end
    end
  end
  
  
  include QSexp::Body
  def build_str ident = 0
    l = "#{tab = (" "*ident)}public #{type} #{name} {"
    
    if @block_stmt
      l += "\n" + 
      @block_stmt.build_str(ident+2)+
      "\n#{tab}}"
    else
      l += " get; set;#{default ? " default = #{default};" : ""}}"
    end
  end
end
