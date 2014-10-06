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
      return "delegate"    if @modifier[:delegate]      
    end    
  end
  
  def declare_scope
    if @modifier
      return "static"    if @modifier[:static]                
    end 
  end
end

module Dot2
  attr_accessor :start, :last
  def initialize *o
    super
    
    on_parented do
      @start = args[0].build_str
      @last = args[1].build_str
    end
  end
end

module For
  attr_reader :name, :low, :high, :type
# for (type name = low; name <= high; name++) {
#
# }

  def initialize *o
    super
    
    on_parented do
      args[1].parented self
      @name = args[0].build_str
      @low =  args[1].start
      @high = args[1].last
    end
  end

  def build_str ident = 0
    "\n#{" "*ident}for (#{type || :int} #{name} = #{low}; #{name} <= #{high}; #{name}++) {\n"+
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
    "#{" "*ident}#{q == "super" ? "base" : (q == "self" ? "this" : q)}"
  end
end

module Super
  def build_str ident = 0
    "#{" "*ident}base(#{args[0].build_str})"
  end
end

module ZSuper
  def build_str ident = 0
    "#{" "*ident}base"
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
  attr_reader :name, :super_class, :implements
  include Body
  def initialize *o
    @implements = nil
    super
    
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
      else
        raise "#{line}: Invalid inheritance"
      end
    end
    
    @body_stmt = args[2]
  end
  
  def build_str ident = 0
    "\n#{" "*ident}public class #{name}#{super_class ? " : #{super_class}" : ""}#{implements ? (super_class ? ", " : " : ")+implements : ""} {\n"+
    super(ident)+
    "\n#{" "*ident}}"
  end
end

module IfElse
  attr_reader :else_stmt
  def initialize *o
    super
    @else_stmt = args[2]
  end
  
  def build_str ident = 0
     s = "if (#{args[0].build_str}) {\n" +
     args[1].build_str(ident+2) +
    "\n#{" "*ident}} "  
  
    if else_stmt
      s << else_stmt.build_str(ident).gsub(Regexp.new("^#{" "*ident}els"),' els')
    end
    
    return s
  end
end

module If
  include IfElse
  
  def build_str ident = 0
    "\n#{tab=" "*ident}" + super
  end
end

module ElsIf
  include IfElse
  def build_str ident = 0
    s= "else " + super
  end  
end

module Else
  def build_str ident = 0
    "#{tab=" "*ident}else {\n#{args[0].build_str(ident+2)}#{tab=" "*ident}}\n"
  end
end

module Def
  attr_accessor :return_type, :symbol, :parameters
  include Body
  include Declaration
  def initialize *o
    super
    
    unless is_a?(Defs)
      @symbol    = args[0].build_str.to_sym
      @body_stmt = args[2]
    
      @parameters = args[1]
    
      if args[2].args[0].children[0].event == :symbol_literal
        set_explicit_return(args[2].args[0].children.shift)
      end
    else
      @symbol    = args[2].build_str.to_sym
      @body_stmt = args[4]
    
      @parameters = args[3]
        
      if args[4].args[0].children[0].event == :symbol_literal
        set_explicit_return(args[4].args[0].children.shift)
      end
    end
  end
  
  def set_explicit_return item
    @return_type = item.build_str.to_sym
  end
  
  def build_str(ident=0)
    "\n#{" "*ident}#{get_access()} #{declare_scope()} #{declare_kind()} #{return_type || "void"} #{symbol}("+parameters.build_str+")"+
    (delegate? ? ";" : " {\n#{super(ident)+"\n#{" "*ident}}"}")
  end
  
  def delegate?
    @modifier and @modifier[:delegate]
  end
  
  def get_access
    super or "public"
  end
  
  def get_scope
    parent ? parent.get_scope : scope
  end
  
  def declare_scope
    super or (is_a?(Defs) ? "static" : nil)
  end
  
  def declare_kind
    n = nil
    if (n = super)
    elsif get_scope_type != :class
      n = ""
    elsif declare_scope != "static"
      n = "virtual" 
    else
      n = ""
    end

    return n
  end
end

module Return0
  def build_str ident = 0
    (" "*ident) + "return" 
  end
end

module Return
  def build_str ident = 0
    (" "*ident) + "return("+
    args.map do |a| a.build_str(0).gsub(/\n$/,'') end.join(", ")+
    ")"
  end
end

module Next
  def build_str ident = 0
    (" "*ident) + "return("+
    args.map do |a| a.build_str(0).gsub(/\n$/,'') end.join(", ")+
    ")"
  end    
end 

module Defs
  include Def
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

module Each
end

module Binary
  def build_str ident = 0
    super(0)
  end
end

module MethodAddBlock
  def initialize *o
    super
    on_parented do
    if !args[0].args[0]
      extend Each
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
        s=s.strip.gsub(/\(, /,'').gsub(/}\)$/,"}").gsub(Regexp.new("^#{" "*(ident*2)}"),'    ')
      elsif !args[0].args[1].args[0]
        s=(" "*ident)+s.strip.gsub(/\(, /,'(').gsub(/}\)$/,"})")
      end
    
      s
    else
      super
    end
    
  rescue => e
    raise "LINE: #{line}, #{event}\n#{e}\n#{e.backtrace[0..3].join("\n")}"
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
  
    super or "#{[:static, :class].index(n=args[0].args[0].type) ? "#{get_access()} #{n} " : (args[0].args[0].type == :instance) ? "public " : ""}"
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
    s << typed_parameters.map do |prm|  prm.build_str end.join(", ") if typed_parameters         
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
    else
      super
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
  rescue => e
    puts "LINE: #{line}, EVENT: #{event}: #{args[0].event} ****"
    raise e
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

module ConstPathRef
  def build_str
    args.map do |a| a.build_str end.join(".")
  end
end

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

module ARef
  def build_str ident = 0
    (" "*ident) +
    args[0].build_str + "[" +
    args[1].build_str +
    "]"
  end
end

module New
  attr_reader :method, :type
  def self.match? *o
    (o[1].event == :var_ref or o[1].event == :const_path_ref) and (o[3].string == "new" or o[3].string =~ /^new_/)
  end
  
  def initialize *o
    super
    @type   = args[0].build_str
    if args[2].build_str =~ /^new\_/
      @method = args[2].build_str.gsub(/^new\_/, "")
    elsif args[2].build_str =~ /^new/
      @method = args[2].build_str.gsub(/^new/, "")
    end
    
    @method = nil if @method == ""
    
    on_parented do |p|
      def p.build_str ident = 0
        args[0].build_str ident
      end
    end
  end
  
  def build_str ident = 0
    "new #{type}#{method ? ".#{method}" : ""}(#{parent.args[1].build_str()})";
  end
end

module Cast
  def build_str ident=0
    "("+args[0].string+") "
  end
end
end
