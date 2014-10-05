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
      return "delegate"         if @modifier[:delegate]      
    end    
  end
end

module Dot2
  attr_accessor :start, :last
  def initialize *o
    super
    @start = args[0].build_str
    @last = args[1].build_str
  end
end

module For
  attr_reader :name, :low, :high, :type
# for (type name = low; name <= high; name++) {
#
# }

  def initialize *o
    super
    @name = args[0].build_str
    @low =  args[1].start
    @high = args[1].last
  end

  def build_str ident = 0
    "\n#{" "*ident}for (#{type || :int} #{name}; #{name} <= #{high}; #{name}++) {\n"+
      args[2].build_str(ident+2)+
    "\n#{" "*ident}}"
  end
end


module Array
  def initialize *o
    super
  end
  
  def build_str ident = 0
    "#{" "*ident}{"+args[0].children.map do |c| c.build_str() end.join(", ")+"}"
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
      args[0].string.gsub("@",get_scope_type() == :class ? "" : "this.")   
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
    "\n#{" "*ident}public class #{name} {\n"+
    super(ident)+
    "\n#{" "*ident}}"
  end
end

module Def
  attr_accessor :return_type, :symbol, :parameters
  include Body
  include Declaration
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
    "\n#{" "*ident}#{get_access()} #{declare_scope()} #{declare_kind()} #{return_type || "void"} #{symbol}("+parameters.build_str+")"+
    (@modifier[:delegate] ? "" : " {\n#{super(ident)+"\n#{" "*ident}}"}")
  end
  
  def get_access
    super or "public"
  end
  
  def declare_scope
    ""
  end
  
  def declare_kind
    super or "virtual"
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
   a=super(ident-2).split("\n")
   a[1].gsub!(/^  /,'')
   "#{" "*ident}namespace #{name}"+
   a.join("\n")
  end
end

module Block
  include Body
  attr_accessor :delegate_type
  attr_reader :parameters, :body_stmt
  def initialize *o
    super
    @body_stmt = args[1]
    @parameters = args[0].args[0] if args[0]
    @parameters.untyped_parameters.map do |prm|
      n = prm.name
      scope.lvars[n] = :unknown
    end if parameters and parameters.untyped_parameters
  end
  def build_str ident=0
    q = !!parameters
    if q
      q = "(#{parameters.build_str})"
    else
      q = "()"
    end
    "#{q} => {\n#{" "*(ident+2)}"+
    super(ident)+
    "\n#{" "*ident}}"
  end
end

module MethodAddBlock
  def initialize *o
    super
    on_parented do
    if !args[0].args[0]
      if args[0].args[1] and args[0].args[1].is_a?(Item)
        args[1].delegate_type = args[0].args[1].build_str().gsub(";\n",'').to_sym
        args[0].args[1] = nil
      end
    end
    end
  end
  def build_str ident = 0
    if args.length > 1
      s=args[0].build_str(ident)
      s=s.gsub(/\)$/,", ")+args[1].build_str(ident)+")"

      # proc block to closure
      if !args[0].args[0]
        s=s.strip.gsub(/\(, /,'').gsub(/}\)$/,"}")
      end
    
      s
    else
      super
    end
  end
end

module Assignment
  include Declaration
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
         if !args[1].args[1]
           type = :declare_array
         elsif (z=args[1].args[1].args[0].children.length) == 1  
           type = :set_array_length
         else
           type = :set_declare_array
         end
         
         return build_type_array(type,ident)
       end
       
     when :symbol_literal
       return declare_type(ident)
       
     when :method_add_block
       type = args[1].args[1].delegate_type
       type = type ? type.to_s+" " : ""
       d = args[1].build_str(args[1].is_a?(MethodAddBlock) ? ident : 0)
      
       if (is_local?() and new_local?()) or !is_local?
         # Full declaration with assignment
         return "\n#{" "*ident}#{[:class, :namespace].index(get_scope_type()) ? declare_scope() : ""}#{type}"+args[0].build_str(0) + " = "+ d
       else
         # Assignment
         return "\n#{" "*ident}"+args[0].build_str(0) + " = "+ d 
       end
     end
     
    
    if is_local?() and !new_local?()
      "#{" "*ident}"+args[0].build_str(0) + " = "+ args[1].build_str(args[1].is_a?(MethodAddBlock) ? ident : 0)
    elsif !is_local?()
      if args[1].is_a?(String)
        type = get_scope_type != :generic ? "string " : ""
      else
        type = get_scope_type != :generic ? (args[1].is_a?(Single) ? args[1].resolved_type.to_s+" " : "#{args[1].resolved_type} "): ""
      end
      
      d = args[1].build_str(args[1].is_a?(MethodAddBlock) ? ident : 0)
      
      "#{" "*ident}#{[:class, :namespace].index(get_scope_type()) ? declare_scope() : ""}#{type}"+args[0].build_str(0) + " = "+ d
    elsif is_local?() and new_local?()
      get_scope.new_local(args[0].args[0].string, args[0].args[0].type)
      return "#{" "*ident}var "+args[0].build_str(0) + " = "+ args[1].build_str(args[1].is_a?(MethodAddBlock) ? ident : 0)
    end
  end
  
  def declare_type(ident)
     "#{" "*ident}#{get_access} #{args[1].build_str(0)} "+args[0].build_str(0)
  end
  
  def is_local?
    args[0].event == :var_field and args[0].args[0].type == :local
  end
  
  def new_local?
    !get_scope().lvars[args[0].args[0].string]
  end
  
  def build_type_array type, ident=0
    bool = is_local?
  
    typed = "#{args[1].args[0].build_str}"
    case type
    when :declare_array
      return "#{" "*ident}#{[:class, :namespace].index(get_scope_type()) ? declare_scope() : ""}"+typed+"[] #{args[0].build_str(0)}"
    when :set_array_length
      val = "[#{args[1].args[1].args[0].build_str(0).gsub("\n",'').gsub(";",'')}]"
      if bool and new_local?
        get_scope.new_local(args[0].args[0].string, args[0].args[0].type)
        x = "var "
      elsif bool
        x = ""
      else
        x = "#{[:class, :namespace].index(get_scope_type()) ? declare_scope() : ""}"+typed+"[] "
      end
      
      return "#{" "*ident}#{x}#{args[0].build_str(0)} = new #{typed}"+val  
          
    when :set_declare_array
      val = "{#{args[1].args[1].args[0].build_str(0).gsub("\n",", ").gsub(/\, $/,'').gsub(";",'')}}"
      if bool and new_local?
        get_scope.new_local(args[0].args[0].string, args[0].args[0].type)
        x = "var "
      elsif bool
        x = ""
      else
        x = "#{[:class, :namespace].index(get_scope_type()) ? declare_scope() : ""}"+typed+"[] "
      end      
       return "#{" "*ident}#{x}#{args[0].build_str(0)} = new #{typed}[] "+val
    end   
  end
  
  def declare_scope
    return "" if is_local?
  
  "#{[:static, :class].index(n=args[0].args[0].type) ? "#{get_access()} #{n} " : (args[0].args[0].type == :instance) ? "public " : ""}"
  end
  
  def get_access
    r = super
    return r if r
    
    args[0].args[0].type == :instance ? "public" : "protected"
  end
end

class ::Object
  def build_str(ident=0)
    ""
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
  
  attr_accessor :typed_parameters, :untyped_parameters
  def initialize *o
    super 
    @typed_parameters   = args[4].map do |a| Parameter.new(*a) end if args[4]
    @untyped_parameters = args[0].map do |a| Parameter.new(*a) end if args[0]
  end
  
  def build_str ident=0
    s = "#{" "*ident}"
    s << untyped_parameters.map do |prm|  prm.build_str end.join(", ") if untyped_parameters    
    s
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
  def initialize *o
    super
    on_parented do |p|
      if args[2].string == "each"
        z=p.parent
        def z.build_str ident = 0
          args[0].args[0].build_str ident
        end
      end
    end
  end
  
  def build_str ident = 0
    if args[2].string == "each"
      "\n#{" "*ident}foreach (#{parent.args[1].build_str.gsub(";\n",'')} #{parent.parent.args[1].parameters.untyped_parameters[0].build_str} in #{args[0].build_str})"+
      " {\n#{parent.parent.args[1].body_stmt.build_str(ident+2)}#{" "*ident}}"
    end
  end
end

module FCall
  def build_str ident=0
    super
  end
end

module VCall
  def build_str ident=0
    super
  end
end

module Command

end

module Numeric
  def resolved_type
    case args[2].string
    when "f"
      :float
    when "d"
      :double
    end
  end
  
  def build_str ident = 0
    "#{" "*ident}#{args[0].string}#{args[2].string}"
  end
end

module String
  def build_str  ident=0
    '"'+super(ident)+'"'
  end
end

module MethodAddArg
  def build_str ident = 0
    "#{" "*ident}"+args[0].build_str(0) + 
    (args[0].is_a?(Cast) ? "#{args[1].build_str.gsub(";\n",'')}" : "(#{args[1].build_str.gsub(";\n",'')})")
  end
end


module ArgsAddBlock
  def build_str ident = 0
    args[0].build_str.gsub(";\n",', ').gsub(/\, $/,'')
  end
end

module MemberModifier
  FLAGS = [
    :abstract,
    :virtual,
    :override,
    :replace,
    :delegate
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

module Cast
  def build_str ident=0
    "("+args[0].string+") "
  end
end
end
