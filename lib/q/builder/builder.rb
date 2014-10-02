module QSexp
class Scope
  attr_accessor :lvars, :item, :type
  def initialize parent_scope = nil
    @parent_scope = parent_scope
  end
  
  def assign fld, scope, type:nil, value:nil
    case scope
    when :constant
    
    when :local
      lvars[fld] = [type,value]
    end
  end
end

class ClassScope < Scope
  def assign fld,scope, type:nil, value:nil
    case scope
    when :class
       
    when :static
       
    when :instance
       
    else
      super   
    end
  end
end

class NamespaceScope < Scope
  def assign fld,scope, type:nil, value:nil
    case scope
    when :class
       
    when :static
       
    when :instance
       
    else
      super   
    end
  end
end

module Array
  def initialize *o
    super
  end
  
  def build_str ident = 0
    "#{" "*ident}{"+args[0].children.map do |c| c.build_str end.join(", ")+"}"
  end
end

module Variables
  def build_str ident=0
    q = case args[0].type
    when :static
      args[0].string.gsub("@@",'')
    when :class
      args[0].string.gsub("$",'') 
    when :instance  
      args[0].string.gsub("@",get_scope() == :class ? "" : "this.")   
    else
      args[0].string    
    end
    "#{" "*ident}#{q == "self" ? "this" : q}"
  end
end

module VarRef
  include Variables
end

module VarField
  include Variables
end

module Body
  attr_reader :body_stmt
  attr_accessor :scope
  def initialize *o
    if is_a?(QSexp::Class)
      @scope = ClassScope.new(self)
    elsif is_a?(Namespace);
      @scope = NamespaceScope.new(self)
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

module Program
  include Body
  def initialize *o
    super
    @body_stmt = args[0]
    @args.map do |a|
      a = self.parented(nil)
    end
  end
end

module Class
  attr_reader :name, :superclass, :interfaces
  include Body
  def initialize *o
    @interfaces = []
    super
    
    case args[0].event
    when :const_ref
      @name = args[0].build_str
    else
      raise
    end
    
    @body_stmt = args[2]
  end
  
  def build_str ident = 0
    "\n#{" "*ident}public class #{name} {\n#{" "*(ident+2)}"+
    super(ident)+
    "\n#{" "*ident}}"
  end
end

module Def
  attr_accessor :return_type, :symbol, :parameters
  include Body
  def initialize *o
    super
    
    @symbol    = args[0].build_str.to_sym
    @body_stmt = args[2]
    
    @parameters = args[1]
    
    if args[2].args[0].children[0].event == :symbol_literal
      set_explicit_return(args[2].args[0].children.shift)
    end
  end
  
  def set_explicit_return item
    @return_type = item.build_str.to_sym
  end
  
  def build_str(ident=0)
    "\n#{" "*ident}#{get_access()} #{declare_scope()} #{declare_kind()} #{return_type} #{symbol}("+parameters.build_str+") {\n"+
    super(ident)+
    "\n#{" "*ident}}"
  end
  
  def get_access
   "public"
  end
  
  def declare_scope
    ""
  end
  
  def declare_kind
    "virtual"
  end
end

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
    end
  end
  
  def build_str ident = 0
    "#{" "*ident}namespace #{name}"+
   super(ident-2)
  end
end

module Block
  include Body
  def initialize *o
    super
    @body_stmt = args[1]
  end
  def build_str ident=0
    "#{" "*ident} {\n#{" "*(ident+2)}"+
    super(ident)+
    "\n}"
  end
end

module Assignment
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
     case args[1].event
     when :aref
       case args[1].args[0].event
       when :symbol_literal
         if (z=args[1].args[1].args[0].children.length) < 1
           type = :declare_array
         elsif z == 1
           type = :set_array_length
         else
           type = :set_declare_array
         end
         
         return build_type_array(type)
       end
       
     when :symbol_literal
       return declare_type(ident)
     end
     
    
    if is_local?() and !new_local?()
      "#{" "*ident}"+args[0].build_str(0) + " = "+ args[1].build_str(0)
    elsif !is_local?()
      "#{" "*ident}#{[:class, :namespace].index(get_scope()) ? declare_scope() : ""}"+args[0].build_str(0) + " = "+ args[1].build_str(0)
    end
  end
  
  def declare_type(ident)
     "#{" "*ident}#{get_access} #{args[1].build_str(0)} "+args[0].build_str(0)
  end
  
  def is_local?
    args[0].event == :var_field and args[0].args[0].type == :local
  end
  
  def new_local?
    false
  end
  
  def build_type_array type
    typed = "#{args[1].args[0].build_str}"
    case type
    when :set_array_length
      val = "[#{args[1].args[1].args[0].build_str(0).gsub("\n",'').gsub(";",'')}]"
      "#{[:class, :namespace].index(get_scope()) ? declare_scope() : ""}"+typed+"[] #{args[0].build_str(0)} = new #{typed}"+val
    when :set_declare_array
      val = "{#{args[1].args[1].args[0].build_str(0).gsub("\n",", ").gsub(/\, $/,'').gsub(";",'')}}"
      "#{[:class, :namespace].index(get_scope()) ? declare_scope() : ""}"+typed+"[] #{args[0].build_str(0)} = "+val
    end
  end
  
  def declare_scope
  "#{[:static, :class].index(n=args[0].args[0].type) ? "#{get_access()} #{n} " : (args[0].args[0].type == :instance) ? "public " : ""}"
  end
  
  def get_access
    args[0].args[0].type == :instance ? "public" : "protected"
  end
end

class ::Object
  def build_str(ident=0)
    "#{" "*ident}"+self.class.to_s
  end 
end

module Parameters
  class Parameter
    attr_reader :type, :name
    def initialize name, type = nil
      @name = name.build_str
      if type
        @type = type.build_str
        if type.event == :aref 
          @type << "[]"
        end
      end
    end
    
    def build_str ident=0
      "#{" "*ident}#{type}#{type ? " " : ""}#{name.gsub(":","")}"
    end
  end
  
  attr_reader :typed_parameters, :untyped_parameters
  def initialize *o
    super 
    @typed_parameters   = args[4].map do |a| Parameter.new(*a) end
    @untyped_parameters = args[0]
  end
  
  def build_str ident=0
    s = "#{" "*ident}"
    typed_parameters.each do |prm| s << prm.build_str end
    s
  end
end

module Arguments

end

module Reference
  module Array
  
  end
  
  module Variable
  
  end
end

class ::Array
  def parented q
    each do |a|
      a.parented q
    end
  end
end

class ::Symbol  
  def build_str ident=0
    "#{" "*ident}#{self}"
  end
  def parented *o
  
  end
end

class ::Symbol
  def write buff = QSexp::BUFFER, ident=0
    buff << "#{" "*ident}#{self}"
  end
end

module Call
end

module FCall

end

module VCall

end

module Command

end
end
