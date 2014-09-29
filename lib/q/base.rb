# TODO: 
# Interfaces
# Fields
# ! Blocks
# ! param, return type of array
# Class instantiate
# ! primitive array each
# generic type 
# case
# break
# continue
# rescue
# range

module Q
  DECLARE_TYPED = [
    :int,
    :uint,
    :float,
    :char,
    :string,
    :long,
    :ulong,
    :double,
    :bool,
    :struct,
    :enum
  ]
  
  def declare_assign q
  
  end

  class Value
    attr_accessor :type, :string, :buff
    attr_reader :sexp, :parent, :ident    
    def initialize sexp, parent, ident = nil
      @ident = ident ? ident : (parent ? parent.ident : ident)
      @sexp = sexp
      @parent = parent
      
      @buff = @parent.buff
      
      @type = sexp[0]
      @string = sexp[1] == "self" ? "this" : sexp[1]
    end 
    
    def set_buff b
      @buff = []
    end
    
    def write;
      if type == :"@tstring_content"
        bool_str = true
        buff << "\""
      elsif type == :"@ivar"
        buff << "this."
        bool_ivar = true
      elsif type == :"@float"
        bool_flt = true
      end
      
      @buff << (bool_ivar ? @string.gsub(/^\@/,'') : @string)
      
      if bool_str
        buff << "\""
      end
      if bool_flt
        buff << "f"
      end
    end
  end

  class NonArray
    attr_reader :sexp, :parent, :buff
    def initialize sexp, parent
      @sexp = sexp
      @parent = parent
      @buff = parent.buff
    end
    
    def write
      @buff << @sexp.to_s
    end
    
    def set_buff b
      @buff = b
    end
  end

  class Base
    attr_reader :sexp, :parent, :ident, :children, :buff
    def initialize sexp, parent, ident = nil
      @ident = ident ? ident : (parent ? parent.ident : 0)
      @sexp = sexp
      @parent = parent
    
      #@flags = parent.flags
    
      @buff = parent ? parent.buff : []
    
      @children = []
    
      init
      
      perform
    end
    
    def flag flg
      flags << flg
    end

    def x(str)
      buff << "#{" "*(ident < 0 ? 0 : ident)}"+str
    end
    
    def init
    
    end
    
    def to_s
    
    end
    
    def perform
      sexp[1..-1].each do |s| children << build_q(s) end  
    end
    
    def write &b
      children.each do |c|
        c.write
        b.call(c) if b
      end
    end
    
    def set_buff b
      @buff = b
      children.each do |c| c.set_buff b end
    end
    
    def build_q q
      if !q.is_a?(Array)
        NonArray.new(q, self)
      elsif q[0].to_s =~ /^\@/
        Value.new(q, self)
      else
        case q[0]
        when :class
          Klass.new(q,self)
        when :assign
          Assign.new q, self
        when :var_field
          VarField.new q, self
        when :var_ref
          VarRef.new(q, self)
        when :aref_field
          ARefField.new(q,self)
        when :program
          Program.new q, self
        when :method_add_arg
          MethodAddArg.new(q, self)
        when :method_add_block
          MethodAddBlock.new(q,self)
        when :args_add_block
          ArgsAddBlock.new q,self
        when :def
          Def.new q,self
        when :params
          Params.new(q,self)
        when :binary
          Binary.new q,self
        when :paren
          build_q q[1]
        when :return
          Return.new(q,self)
        when :call
          Call.new q,self
        when :fcall
          FCall.new(q,self)
        when :aref
          ARef.new(q,self)
        when :do_block
          Block.new q,self
         
        else
          Base.new q,self
        end
      end
    rescue => e
      puts buff.join
      puts "VeryDescriptiveError: #{q}\nERROR: #{e.to_s}\n#{e.backtrace[0]}"
      exit
    end
  end
  
  module HasMany
    def perform
      sexp[1].each do |s|
        children << build_q(s)
      end
    end
  end
  
  class ARefField < Base
    def perform      
      super
    end
    
    def write
       children[0].write
       buff << "["
       children[1].write
       buff << "]"
    end
  end
  
  class Binary < Base
    def write
      children.each_with_index do |c,i|
        c.write
        buff << " " unless i == children.length-1
      end
    end
  end
  
  class Body < Base
    include HasMany
    
    attr_reader :lvars
    def initialize *o
      @lvars = {}
      @next_def_flags = []
      super
    end    
    
    def perform
      @ident += 2
      super
      
      rem = []
      children.each_with_index do |c,i|
      if c.is_a?(VCall)
        if c.sexp.length == 2 and c.sexp[1][0] == :"@ident"
          if DEF_FLAGS.index[flg = c.sexp[1][1].to_sym]
            rem << i
            @next_def_flags << flg
          end
        end
      end
      end
      rem.each do |i| children.delete_at(i) end
    end    
    
    def write &b
      children.each do |c|
        x(" "*ident)
        
        if c.sexp[0] == :def
          buff << @next_def_flags.join(" ")+" "
          @next_def_flags = []
        end
        
        c.write
      
        if !c.is_a?(Body)
          @buff << ";"
        end

        @buff << "\n"
        
        b.call if b
      end
    end
  end
  
  class VCall < Base; end
  
  class FCall < Base
    def write
      super
      
      return unless buff.last
      
      if buff.last == "puts"
        buff.last.replace "stdout.printf"
        return :puts  
      elsif DECLARE_TYPED.index(n=buff.last.to_sym)
        buff.last.replace("(#{n}) ")
        return n
      end
    end
  end
  
  class Program < Body
  end  
  
  class ARef < Base
    def write
      children[0].write
      buff << "["
      children[1].write
      buff << "]"
    end
  end
  
  class MethodAddArg < Base    
    def write
      n = @children[0].write
      @buff << "(" unless DECLARE_TYPED.index(n)
      if n == :puts and c=children[1].children[0].children[0]
        def c.write
          super
          buff << "+\"\\n\""
        end
      end
      
      @children[1].write
      @buff << ")" unless DECLARE_TYPED.index(n)
    end
  end
 
  class VarField < Base
    def write
      children[0].write
    end
  end
  
  class VarRef < Base
  
  end
  
  class Assign < Base
    def perform
      super
      if children[0].is_a?(VarField) and children[0].children[0].type == :"@ident"
        parent.lvars[children[0].children[0].string] ||= [children[1], false]
      elsif children[0].is_a?(ARefField)
        if children[0].children[0].is_a?(VarRef)
          parent.lvars[children[0].children[0].children[0].string] ||= [children[1], false]
        end 
      end
    end
  
    def assign_array?()
      children[1].sexp[0] == :aref and children[1].sexp[1][0] == :vcall
    end
  
    def declare_array()
      buff << "var "
      children[0].write
      buff << " = new "
      children[1].children[0].write
      buff << "["
      children[1].children[1].write
      buff << "]" 
    end
  
    def assign_lvar?()
      children[0].sexp[0] == :var_field
    end
    
    def lvar_is_new?
      if children[0].is_a?(VarField) and children[0].children[0].type == :"@ident"
        bool = !parent.lvars[children[0].children[0].string][1]
        return bool
      end
    end
  
    def declare_lvar()
      bool = lvar_is_new?
      parent.lvars[children[0].children[0].string][1] = true if parent.lvars[children[0].children[0].string]    
    
      if assign_array?()
        declare_array
        
        return
      end
      
      buff << "var " if bool
      children[0].write
      buff << " = "
      write_right(bool)
    end
  
    def write
      if assign_lvar?()
        declare_lvar()
      
        return
      end
      
      children[0].write
      buff << " = "
      write_right(false)
    end
    
    def write_right bool
      children[1].write
    end
  end
  
  class Klass < Body
    attr_reader :name, :sc, :interfaces
    def init
      n = sexp.delete_at(3)
      
      o = sexp.map do |q| 
        e = build_q(q)
        e.instance_variable_set("@buff", [])
        e
      end
      
      
      @sexp = n
      @name = o[1]
      @sc = o[2]
      @interfaces = []
    end
    
    def write
      @ident -= 4
      buff << "\n"
      name.instance_variable_set("@buff", [])
      s = sc ? (sc.children[0] ? " : "+sc.children[0].string : nil) : nil
      x"class #{name.children[0].sexp[1]}#{s} {"
      super
      x "}"
    end
  end
  
  class self::SArray
    include HasMany
  end
  
  module SignatureType
    def init
      @buff = []
    end
    def write
      bool = @sexp[0] == :aref
      super
      buff << "[]" if bool
    end  
  end
  
  class ReturnType < Base
    include SignatureType
  end
  
  class Def < Body
    attr_reader :name, :params, :return_type
    attr_accessor :flags
    def init
      n = @sexp.delete_at(3)
      d = @sexp
      @name = d[1][1]
      @params = build_q(d[2])
      @sexp = n
      
      if explicit_return_type?
        q = @sexp[1].delete_at(0)
        @return_type = ReturnType.new(q,self,0)
      end
    end
    
    def explicit_return_type?()
      @sexp[1][0][0] == :symbol_literal or (@sexp[1][0][0] == :aref and @sexp[1][0][1][0] == :symbol_literal)
    end
    
    def write
      return_type.write
      @ident -= 4
      buff << "\n"
      x("#{flags || "public virtual"} #{return_type.buff.join()} #{name}(")
      params.write
      buff << ") {\n"
      super
      @ident -= 1
      x(" }\n")
    end
  end
  
  class Param < Base
    attr_reader :name, :type
    def perform
      super
      
      @type = children[1]
      
      @name = children[0]
    end
    
    def write
      if name.is_a?(Value)
        type.write
        buff << " "
        name.write
        buff.last.gsub!(":",'')
      else
        type.write
      end
    end
  end
  
  class Call < Base
    def write
      target = sexp[1]
      what = sexp[3]
      if target[0].to_s =~ /\@float|\@int/
        if ["d","f"].index(what[1])
          buff << "#{target[1]}#{what[1]}"
        else
         super
        end
      else
        super
      end
    end
  end
  
  class MethodAddBlock < Base
    def init
      o = buff
      blk =  sexp.pop
      @buff = []
      q = Base.new sexp, self
      q.write
      if q.buff.last == "each"
        b = Block.new(blk,nil)
        @foreach = ForEach.new(q.buff.join.split(/\.each$/)[0], b)
      else
        sexp << blk
      end
      
      @buff = @parent.buff 
    end
    
    def perform
      if @foreach
        
      else
        super
      end
    end
    
    def write
      if @foreach
        @foreach.write
        buff << @foreach.buff.join
      else
        super
      end
    end
  end
  
  class ForEach
    attr_reader :buff,:target, :block, :ident
    def initialize target, blk
      @target = target
      @block = blk
      @ident = 0
      if blk.children[0] and blk.children[0].children[0]

        @params = blk.params
      end

      @buff = []
    end
    
    def write
      buff << "foreach ( "
      Class.new(Params).new(@params.sexp,self).write
      buff << " in #{target}) {\n"
      cls = Class.new(Body)
      cls.send :include, Iterator
      cls.new(@block.sexp, self).write
      buff << "}\n"
    end
  end
  
  
  
  module Iterator
     def set_lvars(parent = @parent)
      if parent
        p = parent
        until p.respond_to? :lvars
          p = p.parent
        end
        @lvars = p.lvars.clone
      end    
    end
  end
  
  class Block < Body
    include Iterator
    attr_reader :params
    def init
      @params = Params.new(sexp[1][1],self)
      @sexp = [:bodystmt].push sexp[2]
      set_lvars
    end
    
    def write
     if buff.last =~ /\)$/
       bool = true
       buff.last.gsub!(/\)$/, "")
     end
     
     buff << "("
     params.write
     buff << ") => {\n"
     super
     buff << "}#{bool ? ")" : ""}"
     
    end
  end
  
  class Params < Base
    def perform
      if sexp[1]
        sexp[1].each do |q|
          children << Param.new([:param].push(*q), self)
        end
      elsif sexp[5]
        sexp[5].each do |q|
          children << Param.new([:param].push(*q), self)
        end
      end
    end
    
    def write
      children.each_with_index do |c,i|
        c.write
        buff << ", " unless i == children.length - 1
      end;
    end
  end
  
  class Return < Base
    def init
      if sexp[1][0] == :args_add_block and sexp[1][1][0][0] == :paren
        sexp[1][1] = sexp[1][1][0][1]
      end
    end
    
    def write
      buff << "return ("
      super
      buff << ")"
    end
  end
  
  class ArgsAddBlock < Base
    include HasMany
    
    def init
      @b = sexp.pop if sexp.last == false
    end
    
    def write
      children.each_with_index do |c, i|
        c.write
        @buff << ", " unless i == children.length-1
      end
    end
  end
  
  def self.translate code
    sexp = Ripper::sexp(code)
    
    if 1 or  __FILE__ == $0
      PP.pp sexp[1]
    end    
    prog = Q::Program.new(sexp,nil)
    prog.write
    prog.buff.join
  end
end
# methods: always public, overide
#
#
if __FILE__ == $0
require 'pp'
# Methods virtual public
code = "
delagate; virtual
def foo(x:int):int
  $foo = 8
end

class Z < Object
  def n(x:int, y:int[], z:string):int[]
    foo = int[2]
    foo[0] = 1
    foo += 2    

    foo.each do |z:int|
      print(\"%d\",z+1)
      n = int[3]
      n[0] = 8
    end

    ted.fred() do |y, v| 
      puts(6)
      foo = 4
      a = h
    end    
  end
end
"
puts Q.translate(code)
end
