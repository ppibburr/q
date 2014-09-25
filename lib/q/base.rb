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
      @string = sexp[1]
    end 
    
    def write;
      if type == :"@tstring_content"
        bool_str = true
        buff << "\""
      elsif type == :"@ivar"
        buff << "this."
        bool_ivar = true
      end
      
      @buff << (bool_ivar ? @string.gsub(/^\@/,'') : @string)
      
      if bool_str
        buff << "\""
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
  end

  class Base
    attr_reader :sexp, :parent, :ident, :children, :buff
    def initialize sexp, parent, ident = nil
      @ident = ident ? ident : (parent ? parent.ident : 0)
      @sexp = sexp
      @parent = parent
    
      @buff = parent ? parent.buff : []
    
      @children = []
    
      init
      
      perform
    end

    def x(str)
      buff << "#{" "*(ident)}"+str
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
    
    def build_q q
      if !q.is_a?(Array)
        NonArray.new(q, self)
      elsif q[0].to_s =~ /^\@/
        Value.new(q, self)
      else; p q[0]
        case q[0]
        when :assign
          Assign.new q, self
        when:var_field
          VarField.new q, self
        when :program
          Program.new q, self
        when :method_add_arg
          MethodAddArg.new(q, self)
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
        
        else
          Base.new q,self
        end
      end
    end
  end
  
  module HasMany
    def perform
      sexp[1].each do |s|
        children << build_q(s)
      end
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
      super
    end    
    
    def perform
      @ident += 2
      super
    end    
    
    def write &b
      children.each do |c|
        x(" "*ident)
        c.write
      
        if !c.is_a?(Body)
          @buff << ";"
        end
        
        @buff << "\n"
        
        b.call if b
      end
    end
  end
  
  class FCall < Base
    def write
      super
      if buff.last == "puts"
        buff.last.replace "stdout.printf"
        return :puts      
      end
    end
  end
  
  class Program < Body
  end  
  
  class MethodAddArg < Base    
    def write
      n = @children[0].write
      @buff << "("
      if n == :puts and c=children[1].children[0].children[0]
        def c.write
          super
          buff << "+\"\\n\""
        end
      end
      
      @children[1].write
      @buff << ")"
    end
  end
 
  class VarField < Base
    def write
      children[0].write
    end
  end
  
  class Assign < Base
    def perform
      super
      if children[0].children[0].type == :"@ident"
        parent.lvars[children[0].children[0].string] ||= [children[1], false]
      end
    end
  
    def write
      bool = parent.lvars[children[0].children[0].string] ? !parent.lvars[children[0].children[0].string][1] : false
      parent.lvars[children[0].children[0].string][1] = true if parent.lvars[children[0].children[0].string]
      @buff << "var " if bool
      children[0].write
      @buff << " = "
      write_right(bool)
    end
    
    def write_right bool
      if children[1].is_a?(MethodAddArg)
      
        if children[1].sexp[1][0] == :fcall;
          q = children[1].children[1]
          n =  children[1].children[0].children[0].sexp[1]
          if Q::DECLARE_TYPED.index(n.to_sym)
            if bool
              buff << "(#{n}) "
              q.write
            else
              children[1].write
            end
          else
            children[1].write
          end
        end
      else
        children[1].write
      end
    end
  end
  
  class Klass < Body
    def init
    
    end
  end
  
  class self::SArray
    include HasMany
  end
  
  class Def < Body
    attr_reader :name, :params
    def init
      n = @sexp.delete_at(3)
      d = @sexp
      @name = d[1][1]
      @params = build_q(d[2])
      @sexp = n
    end
    
    def write
      @ident -= 3
      x("\npublic type #{name}(")
      params.write
      buff << ") {\n"
      super
      @ident -= 1
      x("}\n")
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
      type.write
      buff << " "
      name.write
      buff.last.gsub!(":",'')
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
  
  class Params < Base
    def perform
      sexp[5].each do |q|
        children << Param.new([:param].push(*q), self)
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
    if __FILE__ == $0
      PP.pp sexp[1]
    end    
    prog = Q::Program.new(sexp,nil)
    prog.write
    prog.buff.join
  end
end

if __FILE__ == $0
require 'pp'
code = "
def n(x:int)
  this.p(1,2)
  this.p(1,2)
  a = 1
  a = 3
  a
  i = char(5)
  i = foo(4)
  n = \"fred\"
  z = 0.0.d
  puts(\"%f\",z)
  return(@foo)
  55.d / 44.0.f
  @foo = 5
end
"
puts Q.translate(code)
end
