#  :Goo[]?
#
# 4
class Class
def define_method *o,&b;
super
end;end
class NilClass
  def line
    Q.line
  end
end

module Q
  class << self
    attr_accessor :last_assign
  end
end

class Symbol; def type; self; end;
  def nullable?
    to_s =~ /\?/
  end
  def array
    to_s =~ /\[/
  end
  
  def q; self.to_s; end
  def build_str ident=0; self.to_s; end
end

def it t
  return false if t.is_a?(Q::ValaSourceGenerator::Cast)
  while t.respond_to?(:arguments) and t.arguments[0]
  return false if t.is_a?(Q::ValaSourceGenerator::Cast)
    t = t.arguments[0]
  end
  t.is_a?(Q::ValaSourceGenerator::Symbol)
end

def is_type?(t)

  return false if t.is_a?(Q::ValaSourceGenerator::Cast)
  t.is_a?(Q::ValaSourceGenerator::ConstPathRef) or t.is_a?(Q::ValaSourceGenerator::Symbol) or t.is_a?(Q::ValaSourceGenerator::DynaSymbol) or (t.is_a?(Q::ValaSourceGenerator::Call) &&
    it(t.target)
  )
end

def type_from_exp(s, c, l)
  return :"GLib.Value" if s =~ /q_gen_value_return/ and !c.is_a?(Q::ValaSourceGenerator::Next)
  if s=~ /^this\.([a-zA-Z0-9]+)\(.*\)$/
    t = c.scope.return_types[$1]
    return t if t
  end
    
  if s=~ /\+this\.([a-zA-Z0-9]+)\(.*\)$/
    t = c.scope.return_types[$1]
    return t if t
  end
    
  if s=~ /\+ this\.([a-zA-Z0-9]+)\(.*\)$/
    t = c.scope.return_types[$1]
    return t if t
  end 

  if s=~ /^([a-zA-Z0-9]+)\(.*\)$/
    t = c.scope.return_types[$1]
    return t if t
  end
    
  if s=~ /\+([a-zA-Z0-9]+)\(.*\)$/
    t = c.scope.return_types[$1]
    return t if t
  end
  
  if s =~ /\+ ([a-zA-Z0-9]+)\(.*\)$/
    t = c.scope.return_types[$1]
    return t if t
  end
    
  if s=~ /^([a-zA-Z0-9]+)\(.*\)\+/
    t = c.scope.return_types[$1]
    return t if t
  end
  
  
  if s=~ /^([a-zA-Z0-9]+)\(.*\) \+/
    t = c.scope.return_types[$1]
    return t if t       
  end
     
  if s=~ /^this\.([a-zA-Z0-9]+)$/
    t = c.scope.fields[$1]
    t = c.scope.properties[$1] unless t

    return t.q.split(" ")[0..0].join(" ") if t
  end
    
  if s=~ /\+this\.([a-zA-Z0-9]+)$/
    t = c.scope.fields[$1]
    t = c.scope.properties[$1] unless t
    return t.q.split(" ")[0..0].join(" ") if t
  end
    
  if s=~ /\+ this\.([a-zA-Z0-9]+)$/
    t = c.scope.fields[$1]
    t = c.scope.properties[$1] unless t
    return t.q.split(" ")[0..0].join(" ") if t  
  end
  
  if s=~ /^this\.([a-zA-Z0-9]+)\+/
    t = c.scope.fields[$1]
    t = c.scope.properties[$1] unless t
    return t.q.split(" ")[0..0].join(" ") if t
  end
  
  if s=~ /^this\.([a-zA-Z0-9]+) \+/
    t = c.scope.fields[$1]
    t = c.scope.properties[$1] unless t
    return t.q.split(" ")[0..0].join(" ") if t                  
  end
  
  if s=~ /^[0-9]+ \>/ or s =~ /^[0-9]+\>/
    return 'bool'
  end
  
  if s=~ /^[a-z] \>/ or s =~ /^[a-z]\>/
    return 'bool'
  end
  
  if s=~ /^[0-9]+ \=\=/ or s =~ /^[0-9]+\=\=/
    return 'bool'
  end
  
  if s=~ /^[a-z] \=\=/ or s =~ /^[a-z]\=\=/
    return 'bool'
  end  
  
  if s=~ /^[0-9]+ \!\=/ or s =~ /^[0-9]+\=\=/
    return 'bool'
  end
  
  if s=~ /^[a-z] \!\=/ or s =~ /^[a-z]\=\=/
    return 'bool'
  end
  
  if s=~ /^[0-9]+ \~\=/ or s =~ /^[0-9]+\=\=/
    return 'bool'
  end
  
  if s=~ /^[a-z] \~\=/ or s =~ /^[a-z]\=\=/
    return 'bool'
  end      
  
  if s=~ /^([a-zA-Z0-9]+)\+/  
    t = l.locals[$1]
    return t.build_str.split(" ")[0] if t and t.build_str.split(" ")[0].to_s != 'infered'
  end
  
  if s=~ /^([a-zA-Z0-9]+) \+/  
    t = l.locals[$1]
    return t.build_str.split(" ")[0] if t and t.build_str.split(" ")[0].to_s != 'infered'
  end  
  
  if s=~ /\+([a-zA-Z0-9]+)$/  
    t = l.locals[$1]
    return t.build_str.split(" ")[0] if t and t.build_str.split(" ")[0].to_s != 'infered'
  end  
  
  if s=~ /\+ ([a-zA-Z0-9]+)$/  
    t = l.locals[$1]
    return t.build_str.split(" ")[0] if t and t.build_str.split(" ")[0].to_s != 'infered'
  end   
  
  t = l.locals[s]
  return t.build_str.split(" ")[0..1].join(" ") if t and t.build_str.split(" ")[0].to_s =~ /unowned|weak/
  return t.build_str.split(" ")[0] if t and t.build_str.split(" ")[0].to_s != 'infered'
  
  return nil
end


def has_local(q, n)
  !!q.scope.locals[n]
end

def local_type(q,n)
  q.scope.locals[n]
end

def known_function_acces(q,s)
  fa = []
  p=q
  while p=p.parent
    fa << p.scope.return_types.keys if p.scope.respond_to?(:return_types)
  end
  fa.flatten
end

def resolves_to_function(q,s)
  fa = known_function_acces(q,s) 
  !!fa.index(s)
end

def do_require pth
  rr = Q::Require.allocate
  rr.path = pth
  rr.ok?

  ::Object.send :perform, rr.path, $reqs
end

$: << File.dirname(__FILE__)
require "source_generator"

def add_package p
  $V_ARGV.push("--pkg", "#{p}") unless $V_ARGV.index("#{p}")
end

def add_flag f
  $V_ARGV << "#{f}" unless $V_ARGV.index("#{f}")
end

def has_pkg(p)
  !!$V_ARGV.index("#{p}")
end

def define_sym s
  $V_ARGV.push("-D",s.upcase)
end

def is_def s
  !!$V_ARGV.index(s)
end


module Q
  def self.at_exit
    @exit ||= []
  end

  module ResolvesAsMacro
    def is_macro?
      ValaSourceGenerator::Command::MACROS[symbol] || ValaSourceGenerator::Command::MACROS[scope.sym.split("::").join(".")+"."+symbol]
    rescue
    end
  end
  
  class ValaSourceGenerator < Q::SourceGenerator
      class ClassScope < Q::Compiler::ClassScope
        attr_accessor :properties, :return_types
        
        def initialize *o
          super
          @properties = {}
          @fields = {}
          @return_types = {}
        end
        
        def add_property symbol, prop
          @properties[symbol] = prop
        end
        
        def fields; @fields; end
      end
  
      class MethodScope  < Q::Compiler::MethodScope
        def mark_has_match_data bool= true
          @match_data = bool
        end
        
        def mark_has_process_exit_status bool =  true
          @proc_exit_status = true
        end
        
        def marked_match_data?
          !!@match_data
        end
        
        def marked_process_exit_status?
          !!@proc_exit_status
        end
      end
      
      class BlockScope < Q::Compiler::BlockScope
      end
      
      class PropertyScope < BlockScope
      
      end

    def handle *o
      res = super
      if !res.is_a?(Modifier) and !res.is_a?(HasModifiers) and !modifiers.empty?

      elsif res.is_a?(HasModifiers)
        modifiers.each do |m|
          res.apply_modifier m
        end
        
        @modifiers = []
      end
      return res
    end
    
    def modifiers
      @modifiers ||= []
    end
  
    class Base < Member
      attr_writer :scope
    
      COMPILER = Q::ValaSourceGenerator
      def initialize *o
        super
        mark_newline true
        mark_semicolon true
      end
      
      def get_indent ident
        " " * ident
      end

      def scope
        return @scope if @scope
        p = self
        while p and p=p.parent
          if @scope=p.scope
            break
          end
        end
        @scope
      end
      
      def parented par
        @parent = par
        @scope = par.get_childrens_scope
        subast.each do |c| c.parented self end   
      end
      
      def get_match_data_variable
        "_q_local_scope_match_data"
      end
    end
  
    module HasModifiers
      MODIFIERS = [
        :public, :private, :static, :class, :delegate, :async, :virtual, :override, :abstract, :signal,:macro,:new, :weak, :unowned
      ]
    
      MODIFIERS.each do |m|
        define_method :"#{m}?" do
          @modifiers.index(m)
        end

        def is_macro?; macro?;end
        attr_accessor :q_macro
        
        define_method :"set_#{m}" do |bool=true|
          if bool
            @modifiers << m
          else
            @modifiers.delete(m)
          end
        end
      end
      
      def apply_modifier m
        send :"set_#{m.name}"
      end

      def macro_vcall n
        if n =~ /^\%/
         # md = (macro_declares[n] ||= n)
        end
      
        md=macro_declares[n] 
        
        if !md
          i=-1

          ss = q_macro
          f=''
          if params.untyped.find do |pp| i+=1;(f=pp.name) == n end
          p Y: symbol, F: f, MD: md = macro_declares[n] ||= "%v#{i+1}_#{ss}"
            macro_declares[md] = md
            p TT: n,MD: md if f=="ba"
          else

            md = macro_declares[n] ||= "%rav#{macro_declares.keys.length}_#{q_macro}"
            macro_declares[macro_declares[n]] = macro_declares[n]
          end
        end
        md
      end
      
      def initialize *o
        super
        @modifiers = []
      end
    end
    
    class Statements < Base
      handles Q::Ast::Statements
      def build_str
        subast.map do |i| i.build_str end.join(", ")
      end
    end

    class Break < Base
      handles Q::Ast::Break
      def build_str ident = 0
Q.line = node.line
""

        (" "*ident)+"break"
      end
    end
    
    class RestParam < Base
      handles Q::Ast::RestParam
      def build_str ident = 0
Q.line = node.line
""

        (" "*ident)+"..."
      end
    end    
    
    module DefaultMemberDeclaration
      include HasModifiers
      
      def initialize *o
        super
        set_public
      end
      
      def visibility
        private? ? :private : (public? ? :public : :public)
      end
      
      def target
        static? ? :static : (class? ? :class : "") 
      end
      
      def async
        async? ? :"async " : ""
      end
    end
    
    module HasBody
      attr_reader :body
      
      def write_body ident = 0
        
        @current = -1
       

        
        
        d = subast.map do |c|
          @current += 1
          s = ""
          hc = nil 
          if (next_child and next_child.node.line != c.node.line) and comment_at(c.node.line)
            s = ""
            if c.marked_extra_newline?
              s = "\n"
              c.mark_extra_newline false
            end
            if c.marked_newline?
              s += "\n"
              c.mark_newline false
            end
            hc = true
          end

          str = c.build_str(ident+2)
          str = str.gsub(";", '') if str.strip =~ /^\#/
          str = "" if ["\n", ";", ";\n", ""].index str.strip
          (c.marked_prepend_newline? ? "\n" : "") +
          str +
          ((c.marked_semicolon? and str != "" and str.strip !~ /^\#/) ? ";" : "") +
          (c.marked_newline? ? "\n" : "") +
          (c.marked_extra_newline? ? "\n" : "") +
          (hc ? write_comment(c.node.line,0).gsub(/\n$/,'') + s : "") +
          write_comments(ident+2)
        end.join
        
                s = ""       
        
        if [Q::ValaSourceGenerator::Def, Q::ValaSourceGenerator::Singleton].index(self.class)
          if get_childrens_scope.marked_match_data?
            s += "#{t=get_indent(ident+2)}string?[] _q_local_scope_empty_str_array = new string[0];\n" + 
            "#{t}MatchInfo _q_local_scope_match_data = null;\n"
          end
          
          if get_childrens_scope.marked_process_exit_status?
            s += "#{get_indent(ident+2)}int? _q_local_scope_process_exit_status = null;\n"
          end
          
          if s != ""
            s += "\n"
            d = s + d
          end
        end
        
        return d
      end
      
      def next_child
        subast[@current+1]
      end
      
      def comment_at l
        Q::COMMENTS[l]
      end
      
      def write_comments ident = 0
        if next_child
          get_comments(subast[@current].node.line+1, next_child.node.line-1).map do |l|
            write_comment(l, ident)
          end.join("\n")
        else
          ""
        end
      end
      
      def write_comment l, ident
        if next_child 
          if !next_child.subast[0] or l >= next_child.subast[0].node.line or l >= next_child.node.line or l >= node.line
            ""
          else
            "" # get_indent(ident)+"// "+comment_at(l).value.strip+"\n"
          end
        end
      end
      
      def get_comments(s,e)
       
        a = []
        for i in s..e
          a << i if Q::COMMENTS[i]
        end

        return a
      end
    end
    
    class RawValaCode < Base
      handles Q::Ast::XStringLiteral
      def type
        :string
      end
      
      def get_type
        :string
      end
      
      def build_str ident = 0
Q.line = node.line
""

        mark_semicolon false
        get_indent(ident) + subast.map do |q|
          q.build_str.gsub(/^"/,'').gsub(/"$/,'')
        end.join
      end

      def mark_template b=true

      end
    end
    
    
    class Array < Base
      handles Q::Ast::Array
      def members
        @members ||= node.members.map do |n| compiler.handle(n) end
      end
      
      def build_str ident = 0

Q.line = node.line
""
        return "{"+members.map do |m| m.parented(self);m.build_str end.join(", ")+"}" unless parent.is_a?(ObjectConstruct) or parent.is_a?(JSONStr) or parent.is_a?(QHash) or parent.is_a?(Array)
        return "["+members.map do |m| m.parented(self);m.build_str end.join(", ")+"]" if parent.is_a?(JSONStr) or parent.is_a?(QHash) or parent.is_a?(Array)
      end
    end
    
    class VarRef < Base
      include ResolvesAsMacro
      handles Q::Ast::VarRef

      def variable
        subast[0]
      end
      
      def kind
        if variable.node.respond_to? :kind
          return variable.node.kind
        end
        
        return :keyword
      end
      
      def symbol
      p = self

        while p=p.parent
          if p.is_a?(HasModifiers)
            if p.macro?
        
              unless kind == :global or kind == :constant
                
                return p.macro_vcall(variable.symbol) unless kind == :global or variable.is_a?(KeyWord)
              end
              break
             # return "MANGLED_#{variable.symbol}"
            end
          end
        end

        if scope and scope.member.is_a?(HasModifiers) and scope.member.is_macro?
          return "#{scope.member.q_macro}_q_macro_arg_"+variable.symbol.to_s+"_eqma" unless kind == :global or kind == :constant or variable.is_a?(KeyWord)
        end
        case variable.symbol.to_s
        when "M"
        #if symbol.to_s == "M"
          return "%n_args"
        #end
        when "CWD"
          return "GLib.Environment.get_current_dir()"
        end
        variable.symbol
      end
      
      def build_str ident = 0
Q.line = node.line
""
    
        if kind == :global and symbol.to_s == "~"
          begin;(scope or variable.scope or variable.parent.scope or parent.scope or parent.parent.scope).until_nil do |q|
            if q.is_a?(MethodScope)
              q.mark_has_match_data true
              break
            end
          end;rescue;end
         
          return get_indent(ident) + "(((#{get_match_data_variable} != null) && (#{get_match_data_variable}.fetch_all() != null)) ? #{get_match_data_variable}.fetch_all() : _q_local_scope_empty_str_array)"
        elsif kind == :global and symbol.to_s == "0"
          return get_indent(ident) + "GLib.Environment.get_prgname()"
        elsif kind == :global and symbol.to_s == "?"
          scope.until_nil do |q|
            if q.is_a?(MethodScope)
              q.mark_has_process_exit_status true
              break
            end
          end        
          return get_indent(ident) + "Process.exit_status(_q_local_scope_process_exit_status)"
        elsif kind == :global and symbol.to_s == "$"
          return get_indent(ident) + "(uint)Posix.getpid()"
        elsif m=is_macro?
          return m.perform(0, nil)
        end  

        get_indent(ident) + "#{kind == :instance ? "this." : ""}#{symbol.to_s}"
      end
    end
    

    
    class ARefField < Base
      handles Q::Ast::ARefField
      attr_reader :members
      def initialize *o
        super
        @what = compiler.handle(node.what)
        @what.parented self
        @members = node.members.map do |n| 
          c = compiler.handle(n)
          c.parented self
          c
        end
      end
      def variable
        @what
      end
    end
    
    class StructInitializer < Base
      handles Q::Ast::BraceBlock
      attr_reader :body
      def initialize *o
        super
        @body = node.body.children.map do |s| s.scope = get_childrens_scope;compiler.handle(s) end 
        @body.each do |a| a.parented self end
      end
      
      def get_childrens_scope
        @childs_scope ||= Q::Compiler::StructScope.new(self)
      end
      
      def build_str ident = 0
Q.line = node.line
""

        body.map do |s| s.build_str(ident+2) end.join(", ")
      end
    end
    
    class Regexp < Base
      handles Q::Ast::Regexp
      include Q::Compiler::KnownType
      def initialize *o
        super
      end
      
      def get_type
        :Regex
      end
      
      
      def build_str ident = 0
Q.line = node.line
""

        "/#{node.value}/#{node.modifier ? node.modifier : ""}"
      end
    end
    
    class DelegateParameterDeclaration < Base
      handles Q::Ast::BareAssocHash
  
      attr_reader :assoc, :params
      def initialize *o
        n = []
        for i in 0..o[0].subast.length-1
          n << o[0].subast.shift
        end
        super
        @assoc = n.map do |p|
          [compiler.handle(p.label).name, compiler.handle(p.value)]
        end
       
        @params = n.map do |p|
          t = compiler.handle(p.value)

          Parameter.new(compiler.handle(p.label).name, t)
        end
      end
      
      def build_str ident = 0
Q.line = node.line
""
        if parent.parent.parent.parent.is_a?(Singleton)
          begin
            if parent.parent.parent.subast[0].subast[0].name.to_s == "Object"
              return assoc.map do |l,v| "#{l}: #{v.build_str}" end.join(", ")
            end
          rescue;end
        end
        if !parent.parent.parent.parent.parent.parent.is_a?(Delegate) and !parent.parent.parent.parent.parent.is_a?(Signal)
          params.map do |p|
            p.name.to_s + ": " + p.type.to_s
          end.join(", ")
        else
          params.map do |p|
            p.type + "#{p.array ? "[]" : ""}" + " " + p.name.to_s
          end.join(", ")
        end
      end
    end



    
    
    class Command < Base
      class Macro
        def initialize body,m=nil
          @body = body
          @m = m
        end

        def symbol
          (MACROS.find do |n,m| m == self end[0]).gsub(".", '__')
        end

        def v_name pct_var
          vn = "pct_#{pct_var.gsub("%",'')}"
          if @m
            if q=@m.macro_declares.find do |k,v| v == pct_var and k != pct_var end
              vn += "_#{q[0]}"
            end
          end
          n = @m ? vn : ""
        end

        attr_reader :rval
        def perform ident, args
          vars = {}

          if args.is_a?(ArgParen)
            args = args.subast[0]
            args = args.subast if args and args.subast.is_a?(ArgsAddBlock)
          end
          
          s=@body.strip
          @body = @body + ";" if s =~ /\n/

          s= @body.split("\n").map do |l|
            (" "*ident)+l
          end.join("\n")

          ms = symbol.split("__")
          ms = ms[0..-2].join("::")+".#{ms[-1]}"
          s=(" "*ident)+"/** Q Macro: #{ms} **/"+s+" /** END_Q **/" if $CM

          #STDOUT.puts "MACRO: template\n#{s}" if $LMACRO

          s=s.gsub(/\%n_args/, args ? args.subast.length.to_s : '0')

          if s =~ /\%qva/
          ma = "\n// Q Macro Value[]\n//\n#{" "*ident}Value?[] #{qva="_q#{Macro.next_var_name}_#{symbol}_qmva"}={};\n"+args.subast.map do |qqq|
            "#{" "*ident}Value? #{qv="_q#{Macro.next_var_name}_#{symbol}_qmv"} ="+qqq.build_str+";\n\n"+
            "#{" "*ident}#{qva} += #{qv};\n"
          end.join()
            p MA: s=ma+"\n\n"+s
            s=s.gsub("%qva", qva)
          end

          if s =~ /\%argv_s/
          ma = "{"+args.subast.map do |qqq|
            qqq.build_str
          end.join(",")+"}"
            s=s.gsub("%argv_s", ma)
          end          
          
          while s =~ /\%v([0-9+])_#{symbol}/
            m1=$1
#p s
            v = args.subast[i=$1.to_i-1].build_str
            #p VS:
            bs=v#, m: m1, a:
            args.subast[i=$1.to_i-1]
            v = args.subast[i].node.arguments[0].name rescue 'void' if v =~ /^\%v([0-9+])/
            v=bs if v==""
            v = "void" if args.subast[i=m1.to_i-1] == nil
            p = args.subast[i] if args
            while p and p=p.parent
              if p.is_a?(HasModifiers) and p.macro?
                ov=v
                v = p.macro_declares[v]
                v=ov unless v

                om=true
                break
              end
            end


            v = 'null' if v==''
            v = '' if v.strip == 'void'
            
            s = s.gsub("%v"+m1+"_#{symbol}", v)
          end

          while s =~ /\%rav([0-9]+)_#{symbol}/
            s = s.gsub(q="%rav"+$1+"_#{symbol}", (vars[q] ||= (Macro.next_var_name+"_#{symbol}_#{v_name(q)}")))
          end

          if s =~ /\%return (.*)/
            @rval = $1
            s=s.gsub("%return #{rval}",'')
          end

          s=s.gsub(" = ;", " = null;")

          #STDOUT.puts "MACRO: expanded\n#{s}" if $LMACRO
          s
        end

        @id=-1
        def self.next_var_name
          "_q#{@id+=1}_"
        end

        def self.from_def(m,args, body)
          ins = allocate
          p m.q_macro, m.symbol
          args=args.reverse
          var_i = 0
          lv=[]
  
          while body =~ /q_macro_arg_(.*?)_eqma/
          lv << $1 unless lv.index($1)
            begin
            p Y: $1
              i=args.index($1)+1
              pct = "%v#{i}_#{symbol}"
              a=$1
              lv.delete $1
            rescue
              var_i = lv.index($1)
              pct = "%rav#{var_i}_#{symbol}"
              m.macro_declares[$1]||=pct
              a = $1
            end 
            body=body.gsub("#{symbol}_q_macro_arg_#{a}_eqma", pct)
          end
          ins.send(:initialize,body.strip.gsub(/\;$/,'').gsub(/\n/,";\n"),m)
          def ins.perform(ident, args)
            super
          end
        
          ins
        end
      end
      
      MACROS = {:'__FILE__' => fm=Macro.new(''), 'DATA' => dm=Macro.new(''), 'Q.Process.pid' => pid=Macro.new('(uint64)Posix.getpid()')}
      def pid.perform *o
        add_package "posix"
        super
      end
      
      def fm.perform ident, q
        "\"#{Q.filename}\""
      end

      def dm.perform ident, q
        "\"#{Q::DATA[Q.filename]}\""
      end

      mm=MACROS['Q.at_exit'] = Macro.new('')
      def mm.perform(ident, ast)
        Q.at_exit << ast.subast[0].node.value
        ""
      end

      mm=MACROS['Q.get_macros'] = Macro.new('')
      def mm.perform(ident, ast)
        @body="string[] %rav1_Q__get_macros;
        %rav1_Q__get_macros = {#{MACROS.keys.map do |k| "\"#{k}\"" end.join(',')}};
        %return %rav1_Q__get_macros
        "
        super
      end

      pm=MACROS['Q.package'] = Macro.new('')
      def pm.perform(ident, ast)
        ast=ast.subast[0].subast;
     
        pkgs = ast.map do |q|
          add_package q.value
        end
        @body = ''
        super ident, nil
      end

      fm=MACROS['Q.flags'] = Macro.new('')
      def fm.perform(ident, ast)
        ast=ast.subast[0].subast;
     
        flags = ast.map do |q|
          add_flag q.value
        end
        @body = ''
        super ident, nil
      end

      ifdefp=MACROS['Q.ifdefpkg'] = Macro.new('')
      def ifdefp.perform(ident, ast)
        s=ast.subast[0].build_str.gsub(";",'');

        @body = "#if Q_PKG_#{s.gsub(/\.|\-/,"_").upcase}"
        #puts PKG: @body
       
        super(ident, nil).gsub(";",'');
      end
      
      ifdef=MACROS['Q.ifdef'] = Macro.new('')
      def ifdef.perform(ident, ast)
        s=ast.subast[0].build_str.gsub(";",'');
        @body = "#if #{s}"
        super(ident, nil).gsub(";",'');
      end
      
      elsdef=MACROS['Q.elsdef'] = Macro.new('')
      def elsdef.perform(ident, ast)
        @body = "#else"
        super ident, nil
      end              
       
      enddef=MACROS['Q.defend'] = Macro.new('')
      def enddef.perform(ident, ast)
        @body = "#endif".gsub(";",'');
        super ident, nil
      end    
      
      defs=MACROS['Q.adddef'] = Macro.new('')
      def defs.perform(ident, ast)
        @body = ""
        ast.subast.each do |s|
          define_sym s.build_str
        end
        super ident, nil
      end  

      pai=MACROS['Q.addpkgifdef'] = Macro.new('')
      def pai.perform(ident, ast)
        @body = ""
        #STDOUT.puts IFDEF: ast.subast[0].build_str
        if is_def(q=ast.subast[0].build_str)
        #STDOUT.puts IFDEF: q
          ast.subast[1..-1].each do |s|
            add_package s.build_str
          end
        end
        super ident, nil
      end 
      
      defi=MACROS['Q.adddefif'] = Macro.new('')
      def defi.perform(ident, ast)
        @body = ""
        #STDOUT.puts IFDEF: ast.subast[0].build_str
        if is_def(q=ast.subast[0].build_str)
        #STDOUT.puts IFDEF: q
          ast.subast[1..-1].each do |s|
            define_sym s.build_str
          end
        end
        super ident, nil
      end           
      
      reqif=MACROS['Q.reqifdef'] = Macro.new('')
      def reqif.perform(ident, ast)
        @body = ""
        #STDOUT.puts IFDEF: ast.subast[0].build_str, Q: :here
        if is_def(q=ast.subast[0].build_str)
        #STDOUT.puts IFDEF: q, LOAD: true
          ast.subast[1..-1].each do |s|
              do_require s.node.value
            
          end
        end
        super ident, nil
      end  
      
      reqifn=MACROS['Q.reqifndef'] = Macro.new('')
      def reqifn.perform(ident, ast)
        @body = ""
        #STDOUT.puts IFDEF: ast.subast[0].build_str
        if !is_def(q=ast.subast[0].build_str)
        #STDOUT.puts IFDEF: q
          ast.subast[1..-1].each do |s|
              rr = Q::Require.allocate
              rr.path = s.node.value
              rr.ok?

              ::Object.send :perform, rr.path, $reqs
            
          end
        end
        super ident, nil
      end               
                  
      hp=MACROS['Q.have_pkg'] = Macro.new('')
      def hp.perform(ident, ast)
        @body = "#{has_pkg(ast.subast[0].build_str)}"
        super ident, nil
      end         
       
      em=MACROS['Q.eval'] = Macro.new('')
      def em.perform(ident, ast)
        ast=ast.subast[0].subast;
       
        t = ast[0]
      
        case t.value
        when "string"
          @body="\"#{eval ast[1].node.value}\""
        when "string[]"
          a=eval(ast[1].node.value)
          @body="{#{a.map do |q| "\"#{q}\"" end.join(", ")}}"
        when /(\[\])$/
          @body="{#{eval(ast[1].node.value).join(", ")}}"        
        else
          @body="#{eval ast[1].node.value}"
        end
        super ident, nil
      end

      Dir.glob("#{File.join(File.dirname(__FILE__),"..","..")}/*.vala.macro").each do |f|
        n=File.basename(f).split(".")[0..-2]
        MACROS[n.join(".")] = Macro.new(open(f).read)
      end

      Dir.glob("./*.vala.macro").each do |f|
        n=File.basename(f).split(".")[0]
        MACROS[n] = Macro.new(open(f).read)
      end

      include ResolvesAsMacro
      handles Q::Ast::Command
      
      def build_str ident = 0
Q.line = node.line
""

        t = get_indent(ident)
        if (subast[0].symbol.to_sym == :struct or subast[0].symbol.to_sym == :namespace or subast[0].symbol.to_sym == :enum)
          if subast[1]
            q = subast[0].symbol.to_sym  
            (t=subast[1].subast[0])
            if (cb = t.is_a?(Klass)) or t.is_a?(IFace)
              t.set_struct true if cb
              t.set_namespace true unless cb or subast[0].symbol.to_sym == :enum
              if subast[0].symbol.to_sym == :enum
                t.set_enum true 
                Enum.from(t)  
              end
              
              mark_semicolon false
              t.build_str ident
            else
              Q::compile_error self, "in `#{q}` target must be #{cb ? "class" : "module"}."
            end
          else
            Q::compile_error self, "Syntax Error. have '#{q}' but no target"
          end
          
        elsif subast[0].symbol.to_sym == :system
          scope.until_nil do |q|
            if q.is_a?(MethodScope)
              q.mark_has_process_exit_status true
              break
            end
          end  
                  
          "#{t}Process.spawn_command_line_sync(#{subast[1].build_str}, null, null, out _q_local_scope_process_exit_status)"
        elsif subast[0].symbol.to_sym == :sleep
          "#{t}Thread.usleep((ulong)(#{subast[1].build_str} * 1000 * 1000))"
        elsif subast[0].symbol.to_sym == :print
          "#{t}stdout.printf((#{subast[1].build_str}).to_string());"    
        elsif subast[0].symbol.to_sym == :printf
          "#{t}stdout.printf(#{subast[1].build_str});"
        elsif subast[0].symbol.to_sym == :time
          "#{t}new GLib.DateTime.from_unix_local(#{subast[1].build_str})"
        elsif subast[0].symbol.to_sym == :puts
          v=subast[1].subast[0].build_str
          "#{t}stdout.puts((#{v}).to_string()); stdout.putc('\\n');"        
        elsif subast[0].symbol.to_sym == :ref
          v=subast[1].subast[0].build_str
          "ref #{v}"      
        elsif subast[0].symbol.to_sym == :out
          v=subast[1].subast[0].build_str
          "out #{v}"  
        elsif subast[0].symbol.to_sym == :is
          v=subast[1].subast[0].build_str
          vv=subast[1].subast[1].build_str
          "#{v} is #{vv}"               
        elsif subast[0].symbol.to_sym == :require
          mark_newline false
          mark_extra_newline false
          mark_prepend_newline false
          mark_semicolon false
          "" 
        
        elsif (s=subast[0].symbol) == "construct"
          "#{t}#{s} #{subast[1].build_str}"


        elsif (s=subast[0].symbol) == "out"
          mark_semicolon false
          "out #{subast[1].build_str}".gsub(/^\(/,'').gsub(/\)$/,'')
        elsif (s=subast[0].symbol) == "macro"
          mark_semicolon false

          n = scope.sym.split("::").join('.')+"."+subast[1].subast.shift.build_str rescue subast[1].subast.shift.build_str
          m = MACROS[n] = Macro.new(subast[1].subast[0].node.value)

          subast = self.subast
          
          m.singleton_class.define_method :perform do |*o|
            if req = subast[1].subast[1]
              rr = Q::Require.allocate
              rr.path = req.node.value
              rr.ok?

              ::Object.send :perform, rr.path, $reqs
            end

            super *o
          end

          ''
        elsif macro = MACROS[subast[0].symbol]
          mark_semicolon false
          marked_semicolon false
          macro.perform(ident, subast[1]).gsub(/[ ]+\;[ ]+\n/,'')
        elsif (s=subast[0].symbol) != "construct"
          "#{t}#{s}(#{subast[1].build_str})"
        end
      end

      def is_macro?
        MACROS[subast[0].symbol]
      end
    end
    
    class Value <  Base
      handles Q::Ast::Command, Command do
        subast[0].symbol.to_sym == :Value
      end
      
      def build_str ident=0
        (" "*ident)+"GLib.Value #{Q.last_assign} = #{subast[1].build_str};"
      end
    end


    class ObjectConstruct <  Base
      handles Q::Ast::Command, Command do
        subast[0].symbol.to_sym == :Object
      end
      
      def build_str ident=0
      list = ""
      list = ", "+subast[1].subast[1].assoc.map do |n,v| v.parented(self);"\"#{n}\", #{v.build_str}" end.join(", ") rescue ""
      typeof = subast[1].subast[0].build_str
      cast = typeof =~ /^[A-Z]/ ? "(#{typeof})" : ""
      typeof = typeof =~ /^[A-Z]/ ? "typeof(#{typeof})" : typeof
        "#{cast}Object.new(#{typeof}#{list})"
      end
    end

    class QHash <  Base
      handles Q::Ast::QHash
      def initialize *o
        super

      end
      def build_str ident=0
        subast[0].parented(self)
        "{#{subast[0].build_str}}"
      end
    end
    
    class AssocListFromArgs <  Base
      handles Q::Ast::AssocListFromArgs
               def initialize *o
        super
  
      end

      def build_str ident=0
      
        subast.map do |c| c.parented(self.parent);c.build_str end.join(",")
      end
    end
    
        
    class AssocNew <  Base
      handles Q::Ast::AssocNew
      
      def initialize *o
        super
        
      end
      def build_str ident=0
        value.parented(self.parent)
        #subast[0].node.name + ", #{subast[1].build_str}"
        v = value.build_str
        p = Parameter.new(name, value)
        if !value.is_a?(Array) and !value.is_a?(QHash)
          if p.type.to_s !~ /int|bool|string|null/
            v = "$(#{v})"
          elsif p.type.to_s == 'string'
            v = v.gsub(/^\@/,'')
          end
        end
        "\"#{name}\": #{v}"
      end
      
      def name; node.label.name end
      def value; 
        @value ||= compiler.handle(node.value)
      ;end
    end
    
    class JSONStr <  Base
      handles Q::Ast::Command, Command do
        subast[0].symbol.to_sym == :JSON
      end
      
      def build_str ident=0
      list = subast[1].subast[0].assoc.map do |n,v| v.parented(self);
        if !v.is_a?(Array) and !v.is_a?(QHash)
        p = Parameter.new(n, v)
        v = v.build_str
          if p.type.to_s !~ /int|bool|string|null/
            v = "$(#{v})"
          elsif p.type.to_s == 'string'
            v = v.gsub(/^\@/,'')
          end
        end 
        "\"#{n}\": #{v.build_str}"
      end.join(", ")
        "@\"{#{list.inspect.gsub(/^\"/, '').gsub(/\"$/,'')}}\""
      end
    end    
    
    class JS < Base
      handles Q::Ast::Command, Command do
        subast[0].symbol.to_sym == :JS
      end
      
      def build_str ident=0
        do_require("Q/jsc") unless @req
        @req = true
         c = subast[1].subast[0].build_str
      funcs=""
      list = []
      props = ""
      subast[1].subast[1].assoc.each do |n,v| v.parented(self);
      
        if !v.is_a?(Array) and !v.is_a?(QHash)
        p = Parameter.new(n, v)
        v = v.build_str
        
          if p.instance_variable_get("@t").subast[0].is_a?(Q::ValaSourceGenerator::Proc)
            funcs << ".set_func(\"#{n}\", #{v})"
            next
          elsif p.type.to_s !~ /int|bool|string|null/
            t = local_type(self,v)
            t =  t ? t.type : nil
            if t and (t.to_s == "JSC.Value")
              props << ".set_prop(\"#{n}\", #{v})"
              next
            end
            
            if resolves_to_function(self, "#{v}") and !has_local(self, "#{v}")
              funcs << ".set_func(\"#{n}\", #{v})"
              next
            else
              v = "$(#{v})"
            end
          elsif p.type.to_s == 'string'
            v = v.gsub(/^\@/,'')
          end
        end 
        
        list << "\"#{n}\": #{v.build_str}"
      end
      list = list.join(", ")
        "new Q.JSCValue.build(#{c}, @\"_q_bjsc_v = {#{list.inspect.gsub(/^\"/, '').gsub(/\"$/,'')}}; _q_bjsc_v;\")#{funcs}#{props}.value"
      end
    end      
    
    class JSPlugin < JS
      handles Q::Ast::Command, Command do
        subast[0].symbol.to_sym == :JSPlugin
      end
      
      def build_str ident=0
        super(ident).gsub(/^new Q.JSCValue.build/, "new Q.JSPlugin.build").gsub(/\.value$/,"")
      end
    end    
    
    class JSPluginClass < JS
      handles Q::Ast::Command, Command do
        subast[0].symbol.to_sym == :JSPluginClass
      end
      
      def build_str ident=0
        super(ident).gsub(/^new Q.JSCValue.build/, "base.build").gsub(/\.value$/,"").split("_q_bjsc_v;\"\).").join("_q_bjsc_v;\"\);\n#{get_indent(ident)}")
      end
    end     
    
    class ObjMember < Base
      handles Q::Ast::Field
      def build_str ident = 0
Q.line = node.line
""

        "#{subast[0].build_str}.#{subast[1].symbol}"
      end
      
      def symbol
        build_str
      end
      
      def kind
        :field
      end
    end
    
    class Using < Base
      handles Q::Ast::Command, Command do
        subast[0].symbol.to_sym == :using
      end
      def build_str ident = 0
Q.line = node.line
""

        get_indent(ident)+"using #{subast[1].build_str}"
      end  
    end
    
    class GenericTypesDeclaration < Base
      handles Q::Ast::Command, Command do
        subast[0].is_a?(Q::Ast::Variable) and subast[0].symbol.to_sym == :generic_types
      end
      
      attr_reader :types
      def initialize *o
        super      
        @types = o[0].subast[1].subast.map do |t| compiler.handle(t).get_type end        
      end
      
      
      def parented *o
        super
        parent.set_generics self
      end
    end
    
     
    
    class Delegate < Base
      include DefaultMemberDeclaration
    
      handles Q::Ast::Command, Command do
        subast[0].is_a?(Q::Ast::Variable) and subast[0].symbol.to_sym == :delegate
      end
      
      def initialize *o
        super
        
        mark_prepend_newline true
      end
      
      def symbol
        subast[1].subast[0].subast[0].subast[0].subast[0].symbol
      end
      
      def params
        subast[1].subast[0].subast[0].subast[1].subast[0].subast[0]
      end
      
      def return_type
        @rt ||= compiler.handle(subast[1].subast[0].subast[1].node.body.subast[0])
      end
      
      def build_str ident = 0
Q.line = node.line
""

        get_indent(ident) + "#{target} #{visibility} delegate #{return_type ? return_type.get_type : :void} #{symbol}(#{params.build_str.gsub(":",'')})"
    
      end
    end
   
    class Signal < Base
      include DefaultMemberDeclaration
    
      handles Q::Ast::Command, Command do
        subast[0].is_a?(Q::Ast::Variable) and subast[0].symbol.to_sym == :signal
      end
      
      def initialize *o
        super
        
        mark_prepend_newline true
      end
      
      def symbol
        subast[1].subast[0].subast[0].subast[0].symbol
      end
      
      def params
        subast[1].subast[0].subast[1]
        
      rescue => e
     
        nil
      end
      
      def return_type
        if @rt
          return @rt
        end
        q = compiler.handle(subast[1].subast[0].subast[1].node.body.subast[0])
        @rt = q.is_a?(VoidStmt) ? :void : q.get_type
      rescue
        :void
      end
      
      def build_str ident = 0
Q.line = node.line
""

        get_indent(ident) + "#{target} #{visibility} signal #{return_type ? return_type : :void} #{symbol}(#{params.build_str.gsub(":",'')})"
    
      end
    end 
    
    class Property < Base
      include DefaultMemberDeclaration
    
      handles Q::Ast::Command, Command do
        subast[0].is_a?(Q::Ast::Variable) and subast[0].symbol.to_sym == :property
      end
      
      def get_childrens_scope
        @childs_scope ||= PropertyScope.new(self)
      end
      
      def initialize *o
        super
        
        mark_prepend_newline true
      end
      
      def symbol
        subast[1].subast[0].params[0].name
      end
      
      
      def type
        subast[1].subast[0].params[0].type
      end      
      
      def build_str ident = 0
Q.line = node.line
""

        ary = ""
        if subast[1].subast[0].params[0].array
          ary = "[]"
        end
        get_indent(ident) + 
        "#{visibility} #{target} #{type}#{ary} #{symbol}"
      end
    end       
    
    
    class Unary < Base
      handles Q::Ast::Unary
      def kind
        node.kind
      end
      
      def what
        @what ||= compiler.handle(node.what)
      end
      
      def build_str ident = 0
Q.line = node.line
""

        "#{kind.to_s.gsub(/\@$/,'')}#{what.build_str}"
      end 
    end    
    
    class Program < Base
      handles Q::Ast::Program
      include HasBody
      def build_str ident = -2
Q.line = node.line
""

        write_body(ident)+
        if $prog == Q.filename
          Q.at_exit.map do |v|
            v
          end.join("\n\n")
        else
          ""
        end
      end
      
      def initialize *o
        @scope = Q::Compiler::ProgramScope.new(self)        
        super
      end
      
      def get_childrens_scope
        @scope
      end
    end
    
    class Include < Base
      handles Q::Ast::Command, Command do
        subast[0].symbol.to_sym == :include
      end
      
      attr_reader :interfaces
      
      def initialize *o
        super
        @interfaces = subast[1].subast.map do |q| q.build_str end
      end
      
      
      
      def parented *o
        super
        parent.append_includes(self)
      end
      
      def build_str ident = 0
Q.line = node.line
""
; "p why?" ; end
    end

    module IFace
      attr_reader :name, :includes, :generics , :macros  
      include HasBody
      include DefaultMemberDeclaration      
      
      def initialize *o
        @includes = [] 
        super
      end
    
      def append_includes member
        member.interfaces.each do |i|

          next if includes.index(i)
          if i.to_s == "Q.Macros"
            @macros = true
          else
            includes << i
          end
        end
        subast.delete member
      end
      
      def set_generics generics
        raise "Previous Generics Declaration" if @generics
        @generics = generics.types
        subast.delete generics
      end    
      
      def inherits
        @includes.map do |i| i.to_s end
      end
      
      
      def do_inherit?
        !@includes.empty?
      end
      
      def iface_type
        abstract? ? :abstract : (virtual? ? :virtual : nil)
      end 
      
      def name
        if generics
          return node.name + "<" + generics.join(", ")+ ">"
        end
        
        node.name
      end            
    end
    
    class Module < Base
      include IFace
    
      handles Q::Ast::Module
      
      def initialize *o
        super
        
        subast.map do |q| q.parented self end 
        
        mark_semicolon false
        mark_prepend_newline true
      end    

      def get_childrens_scope
        @childs_scope ||= Q::ValaSourceGenerator::ClassScope.new(self)
      end
      
      def build_str ident = 0
Q.line = node.line
""


        s="#{get_indent(ident)}" +
        unless namespace? or enum?
          "#{visibility}#{iface_type ? " "+class_type : ""} interface #{name}#{do_inherit? ? " : #{inherits.join(", ")} " : " "}{\n"
        else
          unless enum?
            "namespace #{name} {\n"
          else
            "#{visibility}#{iface_type ? " "+class_type : ""} enum #{name} {\n" +
            declare_members(ident+2)
          end
        end +
        write_body(ident)+
        "\n#{get_indent(ident)}}"

        if !@macros
          s
        else
          ''
        end
      end
      
      def set_namespace bool = true
        @namespace = bool
      end
      
      def namespace?
        !!@namespace
      end
      
      def set_enum bool = true
        @enum = bool
      end
      
      def enum?
        !!@enum
      end      
    end
    
    module Enum
      attr_accessor :values
      def self.from t
        t.extend self
        t.values = t.subast.find_all() do |x|
        
          x.is_a?(VarRef) or (x.is_a?(Assign) and x.subast[0].is_a?(VarField) and x.variable.kind == :constant)
        
        end
        
        t.values.each do |v| t.subast.delete(v) end
      end
     
      def declare_members ident = 0
        (" " * ident)+values.map do |x|
          if x.is_a?(VarRef)
            x.build_str
          else
            x.subast[0].variable.name + " = " + x.value.build_str
          end
        end.join(",\n#{" " * ident}") + ";" 
      end
    end
    
    class VoidStmt < Base
      handles Q::Ast::VoidStmt
      def initialize *o
        super
        mark_newline false
        mark_semicolon false
        mark_prepend_newline false
      end
      
      
      def build_str ident = 0
Q.line = node.line
""

        ""
      end
    end
    
    class Q::Range < Base
      handles Q::Ast::Dot2
      attr_accessor :first, :last
      def initialize *o
        super
        @first = compiler.handle(node.first).build_str
        @last  = compiler.handle(node.last).build_str
      end
      
      def build_str ident = 0
Q.line = node.line
""

        get_indent(ident)+"#{first}:#{last}"
      end
    end
    
    class For < Base
      handles Q::Ast::For
      include HasBody
      attr_reader :in, :what
      def initialize *o
        super
        mark_extra_newline true
        mark_prepend_newline true
        mark_newline true
        @in = compiler.handle(node.in)
        @what = node.what
        @type = :int
      end

      def get_childrens_scope
        @childs_scope ||= BlockScope.new(self)
      end
      
      def build_str ident = 0
Q.line = node.line if node
""

        p = self
        what = self.what
        while p = p.parent
          if p.is_a?(HasModifiers) and p.macro?

            n = what
            what = (p.macro_vcall(what))
            p wn: n, w: what
            p.macro_declares[n] = what
            p.macro_declares[what] = what
            break
          end
        end
        get_childrens_scope().append_lvar what.to_s, DeclaredType.new(what.to_s, @type)

        if self.in.is_a?(Q::Range)
          "\n#{get_indent(ident)}for (#{@type} #{what} = #{self.in.first}; #{what} <= #{self.in.last}; #{what}++) {\n" +
          write_body(ident)+
          "\n#{get_indent(ident)}}"
        else
          "\n#{get_indent(ident)}foreach (var #{what} in #{self.in.build_str}) {\n" +
          write_body(ident)+
          "\n#{get_indent(ident)}}"
        end
      end
    end
    
    class Klass < Base
      include IFace
      attr_reader :super_class
    
      handles Q::Ast::Klass
      
      def initialize *o
        super
        
        if node.super_class
          @super_class = compiler.handle(node.super_class).build_str.gsub("[", "<").gsub("]", '>')
        end
        
        subast.map do |q| q.parented self end 
        
        mark_semicolon false
        mark_prepend_newline true
        mark_extra_newline
      end
      
      def set_struct bool = true
        @struct = true
      end
      
      def struct?
        !!@struct
      end
      
      def get_childrens_scope
        @childs_scope ||= Q::ValaSourceGenerator::ClassScope.new(self)
      end
      
      def inherits
        if super_class
          a = [super_class.to_s]
        else
          a = []
        end
        a.push(*super)
      end
      
      def do_inherit?
        super or @super_class
      end      
      
      def build_str ident = 0
        Q.line = node.line
        ""

        subast.find_all do |a| a.is_a?(Def) end.each do |a| a.build_str; a.instance_variable_get("@childs_scope").instance_variable_set("@locals", {}); end 

        "#{get_indent(ident)}#{visibility}#{iface_type ? " "+class_type : ""} #{struct? ? "struct" : "class"} #{name}#{do_inherit? ? " : #{inherits.join(", ")} " : " "}{\n"+
        write_body(ident).strip+
        "\n#{get_indent(ident)}}"
      end
    end
    
    class Call < Base
      handles Q::Ast::Call
      attr_reader :target, :what
      def initialize *o
       super
       @target = compiler.handle(node.target)
       @what = compiler.handle(node.call)
      end

      def is_macro?; nil; end

      def is_type?
        return true if node.target.is_a? Q::Ast::SymbolLiteral
        return true if node.target.is_a? Q::Ast::DynaSymbol
        return true if @target.is_a?(Q::ValaSourceGenerator::Type)
        return true if node.target.is_a? Q::Ast::ConstPathRef and node.target.subast[0].is_a?(Q::Ast::SymbolLiteral)
        false
      end
      
      def build_str ident = 0
Q.line = node.line
""

        #if @target.build_str == "Q" and @what.symbol.to_s == "ENV"
        #  return (" "*ident)+"new Q.Env()"
        #end
       
        if !is_type?

         p = self
         str = @target.build_str
         while p = p.parent
           if p.is_a?(HasModifiers)
             if p.macro?
               str=p.macro_declares[str=@target.build_str] || str
               break
             end
           end
         end

          s=get_indent(ident) + str + "." + what.symbol.to_s
          s=s.gsub(/\?$/,'')
        else
          case @target.build_str
          when /^out|ref/
            res = what.symbol.to_s
            p = self
            while p and p=p.parent
              if p.is_a?(HasModifiers) and p.macro?
                res = p.macro_vcall(res)
                break
              end
            end
            s=get_indent(ident) + @target.build_str + " " + res
          when /string|int|char|uint|double|float/
            s=get_indent(ident) + "(#{@target.build_str})" + "" + what.symbol.to_s
         
          else
         # STDOUT.puts "jjjjj"+node.target.inspect
            if is_type?() and node.q != :"::" and (!node.target.respond_to?(:of) or !node.target.of.is_a?(Q::Ast::ARef))
              s=get_indent(ident) + "(#{@target.build_str})" + "" + what.symbol.to_s
            else
              s=get_indent(ident) + @target.build_str + "." + what.symbol.to_s
            end
          end
        end
        s
      end
    end

    class CommandCall < Call
      handles Q::Ast::CommandCall
      def initialize *o
        super
        @arguments = compiler.handle(node.arguments[0])
      end

      def is_macro?
        Command::MACROS[@target.build_str+"."+what.symbol.to_s]
      end
      
      def build_str ident = 0
Q.line = node.line
""

        if m=is_macro?
          return m.perform(ident, @arguments)
        end
        
        if !is_type?
          s=get_indent(ident) + @target.build_str + "." + what.symbol.to_s
          s=s.gsub(/\?$/,'')
        else
  
        #  case what.symbol.to_s
      #    when "index"
       #     s = Command::MACROS['Q.Iterable.find'].perform ident, subast
         # else
            begin
              if (a=subast[0].subast[0]).is_a?(Assign)
                s = get_indent(ident) + (t=(@target.build_str + ".").gsub(/^std\./,'')+"#{what.symbol}") + " #{a.variable.symbol} = #{a.value.build_str}" 
                scope.locals[a.variable.symbol.to_s] = t
                return s
              end
            rescue;end
            s=get_indent(ident) + @target.build_str + "." + what.symbol.to_s
         # end
        end
        s
      end   
    end   
    
    class ZSuper < Base
      handles Q::Ast::ZSuper
      def build_str ident = 0
Q.line = node.line
""

        args = scope.member.params.typed.map do |p| p.name end.join(", ")
        if scope.member.is_a?(Singleton)
          get_indent(ident) + "base(#{args})"
        else
          get_indent(ident) + "base.#{scope.member.symbol}(#{args})"
        end
      end
    end
    
    class Super < Base
      handles Q::Ast::Super
      def build_str ident = 0
Q.line = node.line
""

        args = subast[0].build_str
        if scope.member.is_a?(Singleton)
          get_indent(ident) + "base(#{args})"
        else
          get_indent(ident) + "base.#{scope.member.symbol}(#{args})"
        end
      end
    end    
    
    
    
    class ArgsAddBlock < Base
      handles Q::Ast::ArgsAddBlock
      
      def initialize *o
        a=super
        a
      end
      
      def build_str ident = 0
Q.line = node.line
""

        subast.map do |c|
          c.parented self;
          (c.node.flags[:type] ? "#{c.build_str }#{c.is_a?(ArrayDeclaration) ? "[]" : ""}" : "#{c.build_str }")
        end.join(", ")
      end
    end
    
    class Assign < Base
      handles Q::Ast::Assign
      
      def initialize *o
        super
        if value.is_a?(MethodAddBlock)
          mark_extra_newline
          mark_prepend_newline true
        end 
      end
      
      def is_declaration?
        ((subast[1].node.inspect =~ /\=\:symbol/) or subast[1].is_a?(Type) or (subast[1].is_a?(ConstPathRef) and subast[1].is_a?(Q::Compiler::KnownType))) and !subast[0].is_a?(ARefField)
      end
      
      def assign_local ident=0
        def variable.symbol
          @q||={}
          if m=is_macro?
           
            @q[m] ||= m.macro_vcall(super)

            @sym ||= @q[m]
            m.macro_declares[super] = @sym
            m.macro_declares[@sym] = @sym
            return @sym
          end
          super
        end

        def variable.is_macro?
          @is_macro
        end
p = self
while p and p = p.parent
  break if p.is_a?(HasModifiers)
end
        variable.instance_variable_set("@is_macro", p) if p and p.macro?

      
        Q::compile_error(self,"Cant assign local variable in #{scope.class}") unless scope and ![Q::Compiler::ClassScope].index(scope)

        if scope.declared?(variable.symbol) #or variable.symbol =~ /\%/
          type = scope.get_lvar_type(variable.symbol) rescue :infered
        else
          # warn declaration by infered type
          if type = DeclaredType.new(variable.symbol, value) and !type.infered? and !((value.is_a?(MethodAddArg) or value.is_a?(Call) or value.is_a?(VCall) or value.is_a?(VarRef)) and value.is_macro?)
            bool = value.build_str == type.type.to_s
         #STDOUT.puts value.build_str,type.type.inspect
            return declare_field(type)+ "; " + (bool ? '' : assign_local)
          elsif !subast[0].is_a?(ARefField)
            return declare_field(DeclaredType.new(variable.symbol, nil), ident)
         
          end
        end
 
        #if variable.is_a?(ARefField)
        
           # STDOUT.puts variable.name
            #end
 
        _new = ""
        if (value.is_a?(Command) or value.is_a?(VCall) or value.is_a?(VarRef) or value.is_a?(Call) or value.is_a?(MethodAddArg)) and m=value.is_macro?
                      vs = value.build_str
                      if m.rval
                    
                        return vs+"\n#{variable.symbol}#{do_sets_field} = #{m.rval};"
                      else
                        return "#{variable.symbol}#{do_sets_field} = #{vs};"
                      end
        end
        "#{variable.symbol}#{do_sets_field} = #{_new}#{value.build_str(ident).strip}"
      end
      
      def declare_field type = DeclaredType.new(symbol = variable.symbol, value), ident = 0
        def variable.symbol
          @q||={}
          if m=is_macro?
           
            @q[m] ||= m.macro_declares.keys.index(super) || m.macro_declares.keys.length

             @sym ||= "%rav#{@q[m]}_#{m.q_macro}"
              m.macro_declares[super] ||= @sym
              m.macro_declares[@sym] ||= @sym
              return @sym
          end
          super
        end

        def variable.is_macro?
          @is_macro
        end
p = self
while p and p = p.parent
  break if p.is_a?(HasModifiers)
end
        variable.instance_variable_set("@is_macro", p) if p and p.macro?
        scope.locals[variable.symbol].wrote = true if scope.locals[variable.symbol].is_a?(DeclaredType)
        type = scope.locals[variable.symbol] if scope.locals[variable.symbol].is_a?(DeclaredType)
        scope.append_lvar(type.name, type) unless scope.locals[variable.symbol]

        if type.infered? and value.build_str !~ /^\((.*)\)[a-zA-Z0-9]/
          qqq = ""
          if (value.is_a?(Command) or value.is_a?(VCall) or value.is_a?(VarRef) or value.is_a?(MethodAddArg)) and m=value.is_macro?
            qqq << "#{value.build_str(ident).strip}\n#{(" ")*ident}"
            if m.rval
      
              val_str = m.rval 
            else

              val_str = value.build_str(ident).strip
              qqq = ""
            end
          else
            val_str = value.build_str(ident).strip
          end


          vv = ""
          if val_str.strip == ""
            vv="var"
            if c=scope.class_scope
            if vt = type_from_exp(qqq.strip, c, scope)
              vv = vt; scope.locals[variable.symbol] ||= vt
            end
            end
            "#{vv} #{variable.symbol} = #{qqq}"

          else
          
            vv="var" unless scope.locals[variable.symbol].respond_to?(:wrote) and scope.locals[variable.symbol].wrote
            scope.locals[variable.symbol].wrote = true
            if c=scope.class_scope
              if vt = type_from_exp(val_str.strip, c, scope)
                vv = vt; scope.locals[variable.symbol] ||= vt
              end
            end
            
            "#{qqq}#{vv} #{variable.symbol} = #{val_str}"
          end
        elsif type.infered? and value.build_str =~ /^\(([A-Za-z]+).*\)[a-zA-Z0-9]+/
          n=value.node
          if true#!scope.locals[variable.symbol]
          scope.locals[variable.symbol] ||= $1
          "#{$1} #{variable.symbol} = #{value.build_str}"
          else
            "#{variable.symbol} = #{value.build_str}"
          end
        elsif scope.member.parent.is_a?(PropertyWithBlock)
          "#{variable.symbol} = new #{type.type}[#{type.array.length}]"
        else
          q = "" + 
          if type.array and type.array.length
             qq=[]
             
             if type.array.initializer? and type.array.length > 1
               i = -1
               type.array.iter do |v|
                 i+=1;
                
                 #if type.type == "Value"
                   
                 v = "#{v}"
                 
                 #else
                 #  if type.array.get_type == 'string'
                 #    v = "\"#{v}\""
                 #  end
                 #  if type.array.get_type == 'char'
                 #    v = "'#{v}'"
                 #  end
                 #end
                 qq << "#{v}" 
               end
          
              "#{type.type}[] #{variable.symbol} = {#{qq.join(", ")}}"
            else
              "var #{variable.symbol} = new #{type.type}[#{type.array.length}];"
            end
          elsif type.nullable?
            "#{type.build_str} = null"
          else

            return "#{type.build_str(0,self)}" if !type.infered?
            "var #{variable.symbol} = #{value.build_str}"
          end
        end
      end

      def variable
        if subast[0].is_a?(ObjMember)
          return subast[0]
        end
        
        subast[0].variable
      end
      
      def value
        subast[1]
      end
      
      def do_sets_field
        if subast[0].is_a?(ARefField)
          "[#{subast[0].members.map do |m| m.build_str end.join(", ")}]"
        else
          ""
        end
      end
      
      def build_str ident = 0
Q.line = node.line
""
        Q.last_assign = variable.symbol.to_s
        
        if value.is_a?(Value)
          scope.locals[variable.symbol.to_s] = :"GLib.Value"
          return value.build_str ident 
        end
        
        if variable.respond_to?(:kind)
          case variable.kind
          when :instance
          # @FLD
          vs = value.build_str
          if value.is_a?(ArrayDeclaration)
            vs = "new "+vs +"[#{value.length}]" if !value.initializer? 
          end
            "#{get_indent(ident)}#{scope.is_a?(Q::Compiler::StructScope)? "" : "this."}"+variable.symbol + do_sets_field + " = #{vs}"
          when :local
            if is_declaration?
              s=nil
              s=(get_indent(ident) + "#{variable.symbol} = #{value.build_str}") if (scope.locals[variable.symbol] and value.is_a?(ObjectNew)) or (scope.locals[variable.symbol] and value.is_a?(Cast))
              scope.locals[variable.symbol].wrote = true if scope.locals[variable.symbol].respond_to?(:wrote)
              return s if s
              get_indent(ident) + declare_field + (value.is_a?(Cast) ? " = "+value.build_str : "")
            else
              get_indent(ident) + assign_local(ident)
            end
          else
            "#{get_indent(ident)}"+variable.symbol + do_sets_field + " = #{value.build_str}"          
          end
        else
         # raise "cant assign #{variable.kind}: #{variable.symbol}"

          "#{get_indent(ident)}"+variable.build_str +  do_sets_field  + " = #{value.build_str}"    
        end
      end
    end

    class MAssign < Base
      handles Q::Ast::MAssign
    
      def build_str ident=0
        a=[]
        (t=subast[1].build_str)
        t = t + "[]" if subast[1].is_a?(ArrayDeclaration)
        s=t+" "+subast[0].subast.map do |v| a << v.variable.name; a[-1] end.join(", ")
        
        a.each do |n| scope.locals[n] = t end
        s
      end
    end
    
    
    class Field < Assign

      handles Q::Ast::Assign, Assign do
        scope.is_a?(Q::Compiler::ClassScope) and :var_field == subast[0].event
      end
      
      include DefaultMemberDeclaration
      

      def parented *o
        q  = super
        if scope.is_a?(ClassScope) and (prop=scope.properties[variable.symbol])
          type = DeclaredType.new(symbol = variable.symbol, value)
          prop.default = ((type.array and type.array.length) ? "new #{type.type}[#{type.array.length}]" : "#{value.build_str}")
          parent.subast.delete(self)
        end
        q
      end

      
      def build_str ident = 0
Q.line = node.line
""

        return get_indent(ident) + case variable.kind
        when :constant
          "public const " + declare_field()
        when :class
           vis = variable.name =~ /^\@\@\_\_[a-z]/ ? "private": "public"
          "#{vis} static "+declare_field()
        when :global
          "public class "+declare_field()
        when :instance
           vis = variable.name =~ /^\@\_[a-z]/ ? "private": "public"
          "#{vis} "+declare_field()
        else
          raise "Bad Field"
        end
      end
        
      def declare_field type = DeclaredType.new(symbol = variable.symbol, value)
      if scope.is_a?(ClassScope)
        scope.fields[symbol] = type.build_str
      end
        if type.infered?
          #STDOUT.puts "#{type.inspect}"
          raise "Cant infer field types: #{type.name}, #{type.type}"
        else
          if value.is_a?(Type)
            type.build_str +
            ((type.array and type.array.length) ? " = new #{type.type}[#{type.array.length}]" : "")
          elsif value.is_a?(Q::Compiler::KnownType)
            "#{type.build_str}" + (!value.is_a?(ConstPathRef) ? " = #{value.build_str}" : '')
          elsif type.type == :bool
            "#{type.build_str} = #{value.build_str}"
          elsif type and type.type
            type.build_str
          else
            #STDOUT.puts value,type.inspect
            raise "Cant determine type for field #{symbol}"
          end
        end
      end
      
      
      def kind
        case variable.kind
        when :instance
          ""
        when :class
          "static "
        when :global
          "class "
        when :constant
          "const "
        end
      end
    end
    
    class ARef < Base
      handles Q::Ast::ARef
      FLAG = :aref
      def of
        @of ||= compiler.handle(node.of)
      end
      
      def values
        @values ||= node.values ? compiler.handle(node.values) : nil
      end
      
      def build_str ident = 0
Q.line = node.line
""

        if of.is_a?(DeclaredType)
        "#{of.get_type}[]"
        else
          of.parented self
          values.parented self if values
          
          of.build_str+
          "[#{values.build_str}]"
        end
      end
    end

    class FieldDeclare < Base
      FLAG = :fld_dec
      handles Q::Ast::ARef, ARef do
        (of.flags[:type] or of.is_a?(Ast::ConstPathRef)) and values and values.subast[0].is_a?(Q::Ast::VarRef) and [:global, :instance, :class].index(values.subast[0].variable.kind)
      end
      
      attr_reader :fields, :type
      def initialize *o
        super
        @type     = compiler.handle(node.of)
        @fields   = compiler.handle(node.values) 

        mark_semicolon false
      end
      
      def build_str ident = 0
Q.line = node.line
""

        fields.subast.map do |f| 
          type = DeclaredType.new(f.variable.symbol, self.type, self.type.is_a?(ArrayDeclaration))
          
          scope = case f.variable.kind
          when :instance
            ""
          when :class
            :static
          when :global
            :class
          when :constant
            :const
          else
            return "#{get_indent(ident)}#{type.build_str}"
          end

          "#{get_indent(ident)}public #{scope} #{type.build_str};" 
        end.join("\n")
      end
    end        

    class Type < Base
      FLAG = :type
      include Q::Compiler::KnownType
      handles [Q::Ast::DynaSymbol, Q::Ast::SymbolLiteral]
      
      def value;
        return node.value.to_s if !subast[0]
        subast[0].symbol
      end
      
      def get_type
        value
      end
      
      def build_str ident = 0
Q.line = node.line
""

        value
      end
      
      def out?
        @out
      end
      
      def ref?
        @ref
      end
      
      def owned?
        @owned
      end
      
      def unowned?
        @unowned
      end
      
      def set_ref bool = true
        @ref = bool
      end
      
      def set_out bool = true
        @out = bool
      end     
      
      def set_owned bool = true
        @owned = bool
      end 
     
      def set_unowned bool = true
        @unowned = bool
      end              
    end
    
    class OP < Base
      handles Q::Ast::OP
      
      def initialize *o
        super
      end

      
      def build_str ident = 0
Q.line = node.line
""

        node.kind
      end
    end
    
    class OPAssign < Base
      handles Q::Ast::OPAssign
      attr_reader :left, :right, :op
      def initialize *o
        super
        @left, @op, @right = [node.left, node.op, node.right].map do |q| compiler.handle(q) end
    
      end
    
      def parented *o
        q = super
        @right.parented *o
        q
      end
      
      def build_str ident = 0
Q.line = node.line
""

        p=self
        if left.is_a?(VarField)
          while p=p.parent
            if p.is_a?(HasModifiers)
              if p.macro?
                l= (p.macro_declares[left.variable.symbol] ||= p.macro_vcall left.variable.symbol)
              end
            end
          end
      
          l = left.variable.symbol unless l
        else
          l = left.build_str
        end
        
        case op.node.kind
        when "||="
          mark_extra_newline true
          mark_newline true
          s = "#{get_indent(ident)}if ( #{l} == null) {\n" +
          "#{get_indent(ident+2)} #{l} = #{right.build_str(ident+2).strip};" +
          "\n#{get_indent(ident)}}"
          return s
        end
        
        "#{get_indent(ident)}#{l} #{op.build_str} #{right.build_str(ident+2).strip}"
      end
    end
    
    class KeyWord < Base
      handles Q::Ast::KeyWord
      def initialize *o
        super
      end
      
      def build_str ident = 0
Q.line = node.line
""

        q = if node.value == :nil
          "null"
        elsif node.value == :self
          "this"
        else
          "#{node.value}"
        end
        
        get_indent(ident) + 
        q
      end
      
      def symbol
        build_str.strip.to_sym
      end
    end
    
    class ArrayDeclaration < Type
      FLAG = :type
      handles Q::Ast::ARef, ARef do
        of.flags[:type] or of.is_a?(Q::Ast::ARef)
      end
      
      attr_reader :of, :length
      def initialize *o
        super
        @of = compiler.handle(node.of)
        begin
          len = node.values.subast.map do |n| compiler.handle(n) end.length
          return @length = len if len > 1
          @length = node.values.subast.map do |n| compiler.handle(n) end[0].node.value.to_i if node.values
        rescue
          @length = node.values.subast.map do |n| compiler.handle(n) end[0].symbol if node.values
        end
      end
      
      def value
        of.get_type
      rescue
        of.build_str+"["+compiler.handle(node.values.subast[0]).build_str+"]"
      end
      
      def get_type
        of.get_type
      end

      def iter &b
        node.values.subast.map do |n| compiler.handle(n).build_str end.each do |q| b.call q end
      end

      def initializer?
        node.values.subast.length > 1
      end
    end

    module GenericsType
      attr_reader :iface, :types
      def initialize *o
        super
        @iface = compiler.handle(node.of).build_str
        @types = node.values.subast.map do |n| ResolvedType.new(t=compiler.handle(n), t.is_a?(ArrayDeclaration)).type+"#{t.is_a?(ArrayDeclaration) ? "[]" : ""}" end
      end
      
      def build_str ident = 0
Q.line = node.line
""

        "#{iface}<#{types.join(", ")}>"
      end
      
      def symbol
        build_str
      end
      
      def get_type
        build_str
      end    
      
      def value; get_type; end
    end

    class InheritGeneric < Base
      include GenericsType
      handles Q::Ast::ARef, ARef do
        of.is_a?(Q::Ast::VarRef) and values.subast[0].is_a?(Q::Ast::SymbolLiteral)
      end
    end
    
    class GenericsDeclaration < Type
      FLAG = :type
      include GenericsType
      include Q::Compiler::KnownType
      handles Q::Ast::ARef, ARef, ArrayDeclaration do
        of.is_a?(Q::Ast::SymbolLiteral) and values and values.subast[0] and (values.subast[0].flags[:type] or values.subast[0].is_a?(Q::Ast::SymbolLiteral))
      end
      def initialize *o
        super
        node.flags[:type] = true
      end
    end 
    
    class VCall < Base
      handles Q::Ast::VCall
      def kind
        subast[0].kind
      end
      
      def symbol
        p = self
        while p=p.parent
          if p.is_a?(HasModifiers)
            if p.macro?
            p UU: subast[0].symbol, MD: md = p.macro_vcall(subast[0].symbol)
              return md
            end
          end
        end
        subast[0].symbol
      end
      
      def build_str ident = 0
Q.line = node.line
""

        if !m=is_macro?

          return get_indent(ident) + symbol
        end

        return m.perform(ident,nil) 
      end

      def is_macro?
    
        return Command::MACROS[subast[0].symbol] if Q::ValaSourceGenerator::Variable

        Command::MACROS[subast[0].build_str] || Command::MACROS[scope.sym.split("::").join(".")+"."+subast[0].build_str]
      end
    end
    
    
    
    class Modifier < Base
      handles Q::Ast::VCall, VCall do
        HasModifiers::MODIFIERS.index(subast[0].symbol.to_sym)
      end
      attr_reader :name
      def initialize *o
        super
        compiler.modifiers.push self
        @name = subast.shift.symbol
        
        mark_semicolon false
        mark_newline false
      end
      def build_str ident = 0
Q.line = node.line
""

        ""
      end
    end    
    
    class ConstRef < Base
      handles Q::Ast::ConstRef
    end
    
    class Variable < Base
      handles Q::Ast::Variable
      def symbol
        node.symbol
      end
      
      def name; symbol.to_s; end
      
      def kind
        node.kind
      end
      
      def build_str ident = 0
Q.line = node.line
""

        raise "only backrefs should be here" unless node.kind == :backref or node.kind == :global 
        if symbol.to_s == "$"
          return get_indent(ident) + "Posix.getpid()"
        end

        case symbol.to_s
        when "M"
          return get_indent(ident) + "%n_args"
        when "CWD"
          GLib::Environment.get_current_dir()
        end
        
        if symbol.to_s =~ /^[0-9]+/
          scope.until_nil do |q|
            if q.is_a?(MethodScope)
              q.mark_has_match_data true
              break
            end
          end
                  
          "(#{get_match_data_variable} != null ? #{get_match_data_variable}.fetch("+symbol.to_s.gsub(/^$/, '')+") : _q_local_scope_empty_str_array[0])"
        
        else
          raise "Bad value!"
        end
      end
    end  
    
    class VarField < Base
      handles Q::Ast::VarField
      
      def variable
        node.variable
      end
    end  
    
    class Numerical < Base
      include Q::Compiler::KnownType
      handles Q::Ast::Numerical
      
      def get_type
        node.type
      end
      
      def build_str ident = 0
Q.line = node.line
""

        node.value.to_s + 
        case get_type
        when :float
          ""
        else
          ""
        end
      end
    end 
    
    class FloatingPoint < Base
      include Q::Compiler::KnownType
      handles Q::Ast::Call, Call do
        target.is_a?(Q::Ast::Numerical) and target.type == :float and q == :'.' and ["d","f"].index(call.symbol);
      end
      
      def target
        @target ||= compiler.handle(node.target)
      end
      
      def get_type
        case node.call.symbol.to_sym
        when :d
          :double
        when :f
          :float
        end
      end
      alias :type :get_type
      
      
      def build_str ident = 0
Q.line = node.line
""


        "#{get_indent(ident)}#{target.build_str.gsub(/f|d$/,'')}#{type.to_s[0]}"
      end
    end  
    
    class Return < Base
      handles Q::Ast::Return
      def parented *o
        super
        if !is_a?(Next) and subast[0].subast[0].is_a? Value
          scope.locals["q_gen_value_return"] = :"GLib.Value"
        end
      end
      def build_str ident = 0
Q.line = node.line
""
n = "return"
n = "next" if self.is_a?(Next)
        if !is_a?(Next) and subast[0].subast[0].is_a? Value
          scope.locals["q_gen_value_#{n}"] = :"GLib.Value"
        end
        if subast[0].subast[0].is_a? Value
          Q.last_assign = "q_gen_value_#{n}"
          return get_indent(ident) + "#{subast[0].build_str};\n" + get_indent(ident) + "return (q_gen_value_#{n})"
        end
        return get_indent(ident) + "return (#{subast[0].build_str()})".gsub("[]",'') if subast[0].build_str() != ""
        return get_indent(ident) + "return"
      end
    end
    
    class Return0 < Base
      handles Q::Ast::Return0
      def build_str ident = 0
Q.line = node.line
""

        get_indent(ident) + "return"
      end
    end    
    
    class Next < Return
      handles Q::Ast::Next
    end
    
    class StringLiteral < Base
      include Q::Compiler::KnownType     
      handles Q::Ast::StringLiteral
      
      def type
        :string
      end
      
      def get_type
        :string
      end
      
      def build_str ident = 0
Q.line = node.line
""

        subast[0].build_str(ident)
      end      
    end    
    
    class StringContent < Base  
      include Q::Compiler::KnownType    
      handles Q::Ast::StringContent
   
      def mark_template bool = true
        @marked_template = bool
      end
      
      def marked_template?
        @marked_template
      end
   
      def type
        :string
      end  
      
      def get_type
        :string
      end 
      
      def build_str ident = 0
Q.line = node.line
""

        get_indent(ident) +
        (marked_template? ? "@\"" : "\"")+
        subast.map do |q| q.build_str() end.join() +
        "\""
      end
    end  
    
    class TStringContent < Base
      include Q::Compiler::KnownType    
      handles Q::Ast::TStringContent
    
      def type
        :string
      end 
      
      def value
        node.value
      end
      
      def build_str ident = 0
Q.line = node.line
""

        value
      end   
    end
    
    class If < Base
      include HasBody
      handles Q::Ast::If
      attr_reader :type, :exp, :else
      def initialize *o
        super
        @type = :if
        @exp = compiler.handle(node.exp)
        @exp.parented self
        @else = compiler.handle(node.else) if node.else
      end
      
      def parented *o
        q = super
     
        if @else
          @else.parented self
        end
        
        @else.scope = self.scope if @else

        q
      end
      
      def build_str ident = 0
Q.line = node.line
""

        
        if self.class == Q::ValaSourceGenerator::If
          mark_prepend_newline true
        end
        
        (t=get_indent(ident)) +
        "#{type.to_s.gsub("elsif", "else if")} (#{exp.build_str}) {\n"+
        write_body(ident)+
        "\n#{t}}" +
        (self.else ? ""+self.else.build_str(ident) : "")
      end      
    end
    
    class ElsIf < If
      handles Q::Ast::ElsIf
      def initialize *o
        super
        @type = :elsif
      end
    end

    class Unless < Base
      include HasBody
      handles Q::Ast::Unless
      attr_reader :type, :exp, :else
      def initialize *o
        super
        @type = :if
        @exp = compiler.handle(node.exp)
        @exp.parented self
        @else = compiler.handle(node.else) if node.else
      end
      
      def parented *o
        q = super

        if @else
          @else.parented self
        end
        @else.scope = self.scope if @else
        q
      end
      
      def build_str ident = 0
Q.line = node.line
""

        
        if self.class == Q::ValaSourceGenerator::Unless
          mark_prepend_newline true
        end
        
        (t=get_indent(ident)) +
        "#{type.to_s.gsub("elsif", "else if")} (!(#{exp.build_str})) {\n"+
        write_body(ident)+
        "\n#{t}}" +
        (self.else ? "\n"+self.else.build_str(ident) : "")
      end      
    end
    
    class Begin < Base
      include HasBody
      handles Q::Ast::Begin
      
      attr_reader :rescue, :else, :ensure
      def initialize *o
        super
        @rescue = node.rescue ? compiler.handle(node.rescue) : nil
        @else   = node.else ? compiler.handle(node.else) : nil
        @ensure = node.ensure ? compiler.handle(node.ensure) : nil
      
        mark_prepend_newline true
        mark_extra_newline true
        mark_semicolon false      
      end
      
      def build_str ident = 0
Q.line = node.line
""

        unless self.rescue
          Q::compile_error self, "begin without rescue!"
        end
      
        "#{t=get_indent(ident)}try {\n"+
        write_body(ident)+
        "#{t}} #{self.rescue.build_str(ident)}" +
        (self.ensure ? "} "+self.ensure.build_str(ident) : "") +
        "\n#{t}}"
      end      
    end
    
    class Rescue < Base
      include HasBody
      handles Q::Ast::Rescue
      
      attr_reader :next_rescue, :what, :variable
      def initialize *o
        super
        @next_rescue = node.next_rescue ? compiler.handle(node.next_rescue) : nil
        @what        = node.what ? compiler.handle(node.what[0]) : nil
        @variable    = node.variable ? compiler.handle(node.variable) : nil                
      end
      
      def build_str ident = 0
Q.line = node.line
""

        "#{t=get_indent(ident)}catch (#{what ? what.build_str() : "Error"} #{variable ? variable.variable.symbol : "_q_local_err"}) {\n"+
        write_body(ident) + 
        "#{next_rescue ? "\n#{t}} "+next_rescue.build_str(ident) : ""}"
      end   
    end
    
    class Ensure < Base
      include HasBody
      handles Q::Ast::Ensure     
      def build_str ident = 0
Q.line = node.line
""

        "#{get_indent(ident)}finally {\n"+
        write_body(ident)
      end
    
    end      
    
    class Else < Base
      include HasBody
      handles Q::Ast::Else
      
      def build_str ident = 0
Q.line = node.line
""

        (t=get_indent(ident)) +
        "else {\n"+
        write_body(ident)+
        "\n#{t}}"
      end
    end

    class While < Base
      include HasBody
      handles Q::Ast::While
   
      attr_reader :exp   
      def initialize *o
        super
   
        @exp = compiler.handle(node.exp)

        def self.parented par
          super
          @exp.parented self  
        end
      end
      
      def build_str ident = 0
        Q.line = node.line
        ""

        s = exp.build_str
        s << " != null" unless exp.is_a?(Binary)

        (t=get_indent(ident)) +
        "while (#{s}) {\n"+
        write_body(ident)+
        "\n#{t}}"
      end
    end    

    module InferReturn
      def infer
        if (return_type = self.return_type) == nil
          r_=subast.find do |q| q.is_a?(Return) end
          sa = self
          5.times do
          if !r_ and sa and sa=sa.subast.find do |q| q.is_a?(If) end
            r_=sa.subast.find do |q| q.is_a?(Return) end
          end
          end
          if r_
            qq=r_.subast[0].build_str()
            
            if qq =~ /^\((.*)\)[a-zA-Z0-9]/
              rt = $1
              return_type = nil
            else
              rt = return_type ? (return_type.is_a?(::String) ? return_type : return_type.type) : :void
              #p MT: rt, sym: symbol, qq: qq
              case qq
              when /^[a-zA-Z0-9]+\=\=[a-zA-Z0-9]+$/
                rt = "bool"
              when /^[a-zA-Z0-9]+ \=\= [a-zA-Z0-9]+$/
                rt = "bool"   
              when /^[a-zA-Z0-9]+\!\=[a-zA-Z0-9]+$/
                rt = "bool"
              when /^[a-zA-Z0-9]+ \!\= [a-zA-Z0-9]+$/
                rt = "bool"   
              when /^\"/
                rt = "string"
              when /^\@\"/
                rt = "string"              
              when /^\'/
                rt = "char"
              when /^[0-9]+\./
                rt = "double"
              when /^\-[0-9]+\./
                rt = "double"
              when /^[0-9]/
                rt = "int"
              when /^\-[0-9]/
                rt = "int"  
              when /false|true/
                rt = "bool"
              else
                rt = type_from_exp(qq, self, get_childrens_scope)
                rt = (return_type ? return_type.type : :void) unless rt
              end
            end 
          else
          
            rt = return_type ? return_type.type : :void
          end
        elsif return_type.is_a?(::String)
          rt = return_type
        else
          rt = return_type ? return_type.type : :void
        end
        
        return rt      
      end
    end
    
    class Def < Base
      include HasBody
      include DefaultMemberDeclaration
      include InferReturn
      handles Q::Ast::Def

      def match_type_path q
        if (subast[0].is_a?(ConstPathRef))
          s=subast[0].subast[0]
          while s and s.is_a?(ConstPathRef)
            s = s.subast[0]
          end

          return true if s.is_a?(Type)
        end
      end

      attr_reader :params, :return_type, :macro_declares
      def initialize *o
        super
        @macro_declares = {}
        @params = compiler.handle(node.params)

        if subast[0].is_a?(Type)
          @return_type = ResolvedType.new(subast.shift)
        elsif  match_type_path(self)
          @return_type = subast[0].build_str
          def (subast[0]).build_str ident=0
            ""
          end
        end
        
        mark_prepend_newline true
        mark_semicolon false
        mark_newline true
      end
 
      def symbol
        node.symbol.symbol rescue node.symbol.value
      end
      
      def get_childrens_scope
        @childs_scope ||= MethodScope.new(self)
      end
     
      def build_str ident = 0
        Q.line = node.line
        ""

        plist = params.typed.reverse.map do |p| p.build_str end
        
        params.typed.reverse.each_with_index do |p,i|
          if p.nullable?
            plist[i] = plist[i] + " = null"
          else
            break
          end
        end
        
     
        if macro?
          @q_macro = scope.sym.split("::").join("__")+"__"+symbol.to_s
          body = write_body(0)
          rr = /return \((.*?)\)/
          body =~ rr
          
          rv = $1
          m=Command::Macro.from_def(self,(params.untyped.reverse.map do |p| p.name end), body.gsub(rr,"%return #{rv}"))
          Command::MACROS[scope.sym.split("::").join(".")+"."+symbol.to_s] = m
     
          mark_prepend_newline false
          mark_newline false
        end

        return '' if is_macro?

        
        kind = self.kind
        visibility = self.visibility
        async = self.async
        bool = false
        
        symbol = self.symbol
        
        if symbol.to_sym == :initialize
          if scope.member.struct?
            Q::compile_error self, "Structs do not have 'initialize'"
          end
          rt = ""
          symbol = :construct
          kind = ""
          async = ""
          visibility = ""
          bool = true
        end

        generics = ''
        if @generics
          generics = "<"+
          @generics.map do |g|
            g.is_a?(::String) ? g : g.build_str
          end.join(", ")+
          ">"
        end
        if (delegate == "" or "virtual" == kind) and !abstract?
          h=" {\n"
          params.typed.each do |x| get_childrens_scope.locals[x.name] = x.build_str.split(" ")[0] end

          z=write_body(ident)
          y="\n#{get_indent(ident)}}"
        else
          h=";"
        end

        rt = infer
        
        ret = return_type and (return_type.is_a?(::String) ? return_type =~ /\?$/ : return_type.nullable?)
        if ret and rt.to_sym!=:void
          if !subast.find do |q| q.is_a?(Return) end
            ret = ""#\n\n#{get_indent(ident+2)}return null;"
   
          else
            ret = ""
          end
        else
          ret = ""
        end

        rt = '' if symbol == :construct

        braces = h+(z ? z+ret+y : '')

        if signal != ""
          kind=""
          if z.strip == ""
            braces = ";"
          end
        end

        rta = (return_type.is_a?(::String) ? return_type =~ /\[\]/ : return_type.array) ? "[]" : '' if return_type
        scope.return_types[symbol] = "#{rt}#{rta}" #if scope.is_a?(ClassScope)
        "#{get_indent(ident)}#{target} #{visibility} #{async}#{kind} #{signal} #{delegate}#{weak? ? " weak " : "" }#{unowned? ? " unowned " : "" }#{rt}#{rta} #{symbol}#{generics}#{symbol == :construct ? "" :"(#{plist.reverse.join(", ")}#{params.swarm ? ", ..." : ''})"}" +
        
        braces
      end

      def set_generics generics
        raise "Previous Generics Declaration" if @generics
        @generics = generics.types
        subast.delete generics
      end  
      
      def signal
        @modifiers.index(:signal) ? "signal " : ""
      end
      
      def delegate
        @modifiers.index(:delegate) ? "delegate " : ""
      end
      
      def kind
        if scope.member.is_a?(IFace)
          if scope.member.is_a?(Klass)
            if scope.member.struct?
              return ""
            end
          elsif scope.member.namespace?
            return ""
          elsif scope.member.enum?
            return ""
          end
            
          scope.is_a?(Q::Compiler::ClassScope) ? " #{@modifiers.index(:new) ? "new" : ""} #{@modifiers.index(:override) ? "override" : "#{@modifiers.index(:abstract) ? "abstract" : "virtual"}"}" : ""
        end
      end
    end  
    
    class Binary < Base
      handles Q::Ast::Binary
      attr_reader :right, :left
      def initialize *o
        super
        @left, @operand, @right = [compiler.handle(node.left), node.operand, compiler.handle(node.right)]

      end
      
      def operand
        l = ["&&", "||"]
        if i = [:and, :or].index(@operand.to_sym) 
          return l[i]
        end
        
        @operand
      end
      
      def parented par
        super par

        left.parented self
        right.parented self
      end
      
      def is_regmatch?
        right.is_a?(Regexp) and ["!~","=~"].index(operand.to_s)
      end
      
      def regmatch_type
        return nil unless is_regmatch?
        case operand.to_s
        when "!~"
          :false
        else
          :true
        end
      end
      
      def build_str(ident = 0)
        if is_regmatch?
          begin;scope.until_nil do |q|
            if q.is_a?(MethodScope)
              q.mark_has_match_data true
              break
            end
          end;end
                  
          return "#{get_indent(ident)}(#{right.build_str}).match(#{left.build_str}, 0, out #{get_match_data_variable})"
        end

        if left.is_a?(StringLiteral) and operand == :"*" and right.is_a?(Numerical)
          return "\"#{left.subast[0].subast[0].node.value*right.node.value.to_i}\""
        end 
        
        operand = self.operand

        if operand == :"<<"
          if left.is_a?(VarRef)
            s = left.symbol
            lv = scope.locals[s.to_s]
            if s=="?" or lv && [:int,:uint,:long,:int64,:uint64,:int32,:uint32,:int16,:uint16,:guint,:guint32,:guint64,:guint16,:gint,:gint32,:gint16,:gint64].index(lv.type)
              
            else
              operand = "+=" if operand == :"<<"
            end

          elsif !left.is_a?(Numerical)
            operand = "+=" if operand == :"<<"
          end
        end
        
        "#{get_indent(ident)}#{left.build_str} #{operand} #{right.build_str}"
      end
    end
    
    class Cast < Base
      handles Q::Ast::Binary, Binary do
        ((((left.is_a?(Q::Ast::SymbolLiteral) or left.is_a?(Q::Ast::DynaSymbol)) and operand.to_sym == :"<<") or
        ((left.is_a?(Q::Ast::ConstPathRef)  and left.subast[0].is_a?(Q::Ast::SymbolLiteral)) and operand.to_sym == :"<<")) or (((left.is_a?(Q::Ast::SymbolLiteral) or left.is_a?(Q::Ast::DynaSymbol)) and operand.to_sym == :">") or
        ((left.is_a?(Q::Ast::ConstPathRef)  and left.subast[0].is_a?(Q::Ast::SymbolLiteral)) and operand.to_sym == :">"))) or (left.is_a?(Ast::ARef) and (((left.of.is_a?(Q::Ast::SymbolLiteral) or left.of.is_a?(Q::Ast::DynaSymbol)) and operand.to_sym == :">") or
        ((left.of.is_a?(Q::Ast::ConstPathRef)  and left.of.subast[0].is_a?(Q::Ast::SymbolLiteral)) and operand.to_sym == :">")))
      end
      
      attr_reader :to, :what
      def initialize *o
        super
        @to = compiler.handle(node.left)
        @what = compiler.handle(node.right)
      end
      
      def build_str ident = 0
Q.line = node.line
""

        case to.build_str.strip
        when "out"
                what.parented self if what.is_a?(VarRef)
          "#{to.build_str} #{what.build_str}"
        when "ref"
          what.parented self if what.is_a?(VarRef)
          "#{to.build_str} #{what.build_str}"
        
        else
          "(#{to.build_str})#{what.build_str}"  
        end
      end
    end    
    
    class Singleton < Base
      handles Q::Ast::DefS
      include HasBody
      include DefaultMemberDeclaration
      include InferReturn
      
      attr_accessor :symbol, :params, :return_type, :macro_declares
      def initialize *o
        super
        @macro_declares = {}
        
        @symbol = node.symbol.symbol
        @params = compiler.handle(node.params)
        
        @subast = node.body.subast[0].children.map do |c| compiler.handle(c) end
        @subast.each do |c| c.parented self end
   
        #STDOUT.puts subast[0].node.inspect if subast[0] 
        if (subast[0].is_a?(Type) or (subast[0].is_a?(ConstPathRef) and subast[0].subast[0].is_a?(Type))) or (subast[0].is_a?(Call) and (subast[0].target.is_a?(Type)))
          @return_type = ResolvedType.new(subast.shift)
        end
        
        mark_semicolon false
        mark_newline true
        mark_prepend_newline
      end
      
      def constructor?
        symbol.to_s == "new" or symbol.to_s =~ /^new_/
      end
      
      def static_construct?
        symbol.to_s == "construct"
      end
      
      def get_childrens_scope
        @childs_scope ||= MethodScope.new(self)
      end
      
      def build_str ident = 0
Q.line = node.line
""

        plist = params.typed.reverse.map do |p| p.build_str end
        
        params.typed.reverse.each_with_index do |p,i|
          if p.nullable?
            plist[i] = plist[i] + " = null"
          else
            break
          end
        end

        if macro?
          body = write_body(0)
          rr = /return \((.*?)\)/
          body =~ rr
          rv=$1
          m=Command::Macro.from_def(self,(params.untyped.reverse.map do |p| p.name end), body.gsub(rr,"%return #{rv}"))
          Command::MACROS[scope.sym.split("::").join(".")+"."+symbol.to_s] = m

          mark_prepend_newline false
          mark_newline false
        end

        return '' if is_macro?

        params.typed.each do |x| get_childrens_scope.locals[x.name] = x.build_str.split(" ")[0] end


        bs = write_body(ident)
      
        return_type = self.return_type
        rt = infer
 
        rta = (return_type.is_a?(::String) ? return_type =~ /\[\]/ : return_type.array) ? "[]" : '' if return_type
      
        if !static_construct? and !constructor?
          sig = "#{visibility} static #{rt}#{rta} "+symbol+"(#{plist.reverse.join(", ")}) {\n"
        elsif static_construct?
          sig = "static construct {\n"
        elsif constructor?
          q = ""
          
          if symbol.to_s != "new"
            q = ".#{symbol.to_s.gsub(/^new\_/,'')}"
          end
          
          sig = "#{visibility} #{scope.member.name.to_s.gsub(/\<.*?\>/,'')}#{q} (#{plist.reverse.join(", ")}) {\n"
        end
        scope.return_types[symbol] = "#{rt}#{rta}"
        get_indent(ident) + 
        sig +
        bs +
        "\n#{get_indent(ident)}}"
      end
    end
    
    class MethodAddBlock < Base
      handles Q::Ast::MethodAddBlock
      def build_str ident = 0
Q.line = node.line
""


begin
        args = subast[0].subast[1].subast[0] ? subast[0].subast[1].subast[0].subast.length : 0
        rescue
          args = subast[0].params.untyped.length
        end
        get_indent(ident) + subast[0].build_str().gsub(/\)$/, args == 0 ? "" : ", ") + 
        subast[1].build_str(ident) +
        ")"
      end
    end
    
    class PropertyWithBlock < Base
      include DefaultMemberDeclaration
      include HasBody
      handles Q::Ast::MethodAddBlock, MethodAddBlock do
        subast[0].is_a?(Q::Ast::Command) and subast[0].subast[0].symbol.to_sym == :property;
      end
      
      def get_childrens_scope
        @childs_scope ||= PropertyScope.new(self)
      end
      
      def build_str ident = 0
Q.line = node.line
""

        parent.mark_semicolon false
        mark_semicolon false
        mark_newline true
     
        mark_prepend_newline true
        s = (t = get_indent(ident)) +
        subast.shift.build_str(ident) +
        write_body(ident).gsub(/\(.*?\=\> \{/, ' {').gsub(/\}\);.*?$/,"}\n").gsub("};","}")

        if s =~ /^ *?owned;/
          if s =~ / get \{/
            s=s.gsub("get {", "owned get {")
          end
        end
        
        s.gsub(/^ *?owned\;/,'')
      end
    end      
    
    class StructNew < MethodAddBlock
      handles Q::Ast::MethodAddBlock, MethodAddBlock do
        subast[1].class == Q::Ast::BraceBlock
      end
      
      def build_str ident = 0
Q.line = node.line
""

        get_indent(ident) + subast[0].build_str() +
        " {\n#{get_indent(ident+2)}" +
        subast[1].build_str(ident+2) +
        "\n#{get_indent(ident)}}"
      end
    end
    
    class BlockVar < Base
      handles Q::Ast::BlockVar
    end
    
    class DoBlock < Base
      include HasBody
      handles Q::Ast::DoBlock
      attr_reader :params
      def initialize *o
        super
        @params = compiler.handle(node.params) if node.params
      end
      
      def parented *o
        super
        return unless params

        params.untyped.map do |p|

        get_childrens_scope.append_lvar p.name,DeclaredType.new(p.name, nil) 
        end
      end
      
      def build_str ident = 0
Q.line = node.line
""

        s="(#{params ? params.untyped.map do |p| p.name end.join(", ") : ""}) => {\n" +
        write_body(ident) + 
        "\n#{get_indent(ident)}}"
        
        get_childrens_scope.locals.clear
        
        s
      end
      
      def get_childrens_scope
        if r=@childs_scope
         return r
        end
        r =@childs_scope = BlockScope.new(self)
        
        return r
      end
    end

    class BraceBlock < DoBlock;
      handles Q::Ast::BraceBlock
    end
    
    class MethodAddArg < Base
      include ResolvesAsMacro
    
      handles Q::Ast::MethodAddArg
      
      def parented par
        super par
        subast.each do |c| c.parented self end
      end
      
      def build_str ident = 0
Q.line = node.line
""

        if !m=is_macro?
          get_indent(ident) + subast[0].build_str +
          "(" +
          (subast[1] ? subast[1].build_str : "") +
          ")"
        else
          m.perform ident, subast[1]
        end
      end

      def is_macro?
        if m=Command::MACROS[subast[0].build_str]
          return m
        end

        m=Command::MACROS[parent.scope.sym.split("::").join(".")+"."+subast[0].build_str]
      rescue
      end
    end
    
    class ArgParen < Base
      handles Q::Ast::ArgParen
      
      def build_str ident = 0
Q.line = node.line
""

        subast[0] ? subast[0].build_str : ""
      end
    end    
    
    class FCall < Base
      handles Q::Ast::FCall
      
      def build_str ident = 0
Q.line = node.line
""

        p = self
        q=subast[0].symbol
        while p=p.parent
          if p.is_a?(HasModifiers) and p.macro?
            q = (p.macro_declares[q] ||= p.macro_vcall(q))
            break
          end
        end
        return q.to_s.gsub(/\?$/,'') #if !m=is_macro?
      end
    end    
   

    
    class ObjectNew < Base
      handles Q::Ast::MethodAddArg, MethodAddArg do
        subast[0].is_a?(Q::Ast::Call) and (subast[0].target.is_a?(Q::Ast::ARef)  or (subast[0].target.subast[0].respond_to?(:kind) and subast[0].target.subast[0].kind == :constant) or subast[0].target.is_a?(Q::Ast::ConstPathRef)) and subast[0].call.symbol.to_s =~ /^new/
      end
      
      def build_str ident = 0
Q.line = node.line
""

      method = ""
      
      if subast[0].what.symbol.to_sym != :new and subast[0].what.symbol.to_s !~ /\!$/
        method = "." +
        "#{subast[0].what.symbol}".gsub(/^new\_/,'')
      elsif subast[0].what.symbol.to_s =~ /\!$/
        method = "." +
        "#{subast[0].what.symbol}".gsub(/\!$/,'')
      end
        n="new " if subast[0].what.symbol.to_s !~ /\!$/
        "#{n}#{subast[0].target.build_str.gsub("[", '<').gsub("]", '>')}#{method}(#{subast[1].build_str})"
      end
    end    

    class TypeType < Base
      FLAG = :type
      handles Q::Ast::Call, Call do;
        (target.is_a?(Q::Ast::SymbolLiteral) or target.is_a?(Q::Ast::DynaSymbol)) and (call.symbol.to_s =~ /^ref$/ or call.symbol.to_s =~ /^out$/ or call.symbol.to_s =~ /^(unowned|owned)/)
      end
      
      attr_reader :target, :call
      def initialize *o
        super
      
        @target = compiler.handle(node.target)
        @call   = compiler.handle(node.call)
        
        case node.call.symbol.to_sym
        when :ref
          target.set_ref true
        when :out 
          target.set_out true
        when :owned
          target.set_owned true
        when :unowned
          target.set_unowned true
        end
      end
      
      def parented par
        super
        i = par.subast.index(self)
        par.subast[i] = target
        target.parented par
      end
    end

    class Each < Base
      handles Q::Ast::MethodAddBlock, MethodAddBlock do
        next nil if subast[0].is_a?(Q::Ast::MethodAddArg)
        next nil unless subast[0].is_a?(Q::Ast::Call)  
        next nil if subast[0].target.subast[0].is_a?(Q::Ast::Dot2)      
        subast[0].call.symbol.to_s =~ /^each$/
      end
      
      
      
      def initialize *o
        super *o
        mark_extra_newline true
        mark_prepend_newline true
        mark_newline true
        
        @what     = compiler.handle(node.subast[0]).target
        @var_name = compiler.handle(node.subast[1]).params.untyped[0].name

      end
      
      def build_str ident = 0
Q.line = node.line
""

        what = @what.build_str
        if scope and scope.member.macro?
          @var_name = scope.member.macro_vcall(@var_name)
          what = scope.member.macro_vcall(@what.build_str)
        else
        end
        get_childrens_scope().append_lvar @var_name.to_sym, DeclaredType.new(@var_name.to_sym, nil)
        
        "#{get_indent(ident)}foreach (var #{@var_name} in #{what})"+
        subast[1].build_str(ident).gsub(/^\(.*\=\> \{/, " {")
      end
      
      def get_childrens_scope
        @childs_scope ||= BlockScope.new(self)
      end
    end

    class TypedEach < Base
      handles Q::Ast::MethodAddBlock, MethodAddBlock do
        next nil unless subast[0].is_a?(Q::Ast::MethodAddArg)
        next nil unless subast[0].subast[0].is_a?(Q::Ast::Call)        
        (subast[0].subast[0].target.is_a?(Q::Ast::SymbolLiteral) or subast[0].subast[0].target.is_a?(Q::Ast::ARef)) and subast[0].subast[0].call.symbol.to_s =~ /^in$/
      end
      
      attr_accessor :type, :var_name, :array
      
      def initialize *o
        super *o
        mark_extra_newline true
        mark_prepend_newline true
        mark_newline true
        
        @type     = compiler.handle(node.subast[0].subast[0].target).get_type
        @var_name = compiler.handle(node.subast[1]).params.untyped[0].name
        @array    = compiler.handle(node.subast[0]).subast[1].subast[0].subast[0].symbol
      end
      
      def build_str ident = 0
Q.line = node.line
""

        get_childrens_scope().append_lvar var_name.to_sym, DeclaredType.new(var_name.to_sym, type.to_sym)
        
        "#{get_indent(ident)}foreach (#{type} #{var_name} in #{array})"+
        subast[1].build_str(ident).gsub(/^\(.*\=\> \{/, " {")
      end
      
      def get_childrens_scope
        @childs_scope ||= BlockScope.new(self)
      end
    end

    class Times < Base
      include HasBody
      handles Q::Ast::MethodAddBlock, MethodAddBlock do
        next nil unless subast[0].is_a?(Q::Ast::Call)

        subast[0].call.symbol.to_s =~ /^times/
      end

      def initialize(*o)
        super
        mark_semicolon false
        mark_newline true
        mark_extra_newline true
      end
      
      
      def build_str ident = 0
Q.line = node.line
""

        e = For.allocate
        type = "int"
        _in = Q::Range.allocate
        _in.first = 0
        q=subast[0].target.build_str
        p = self
        while p=p.parent
          if p.is_a?(HasModifiers) and p.macro?
            q = (p.macro_declares[q] ||= p.macro_vcall(q))
            break
          end
        end
        _in.last = q
        what = subast[1].params.untyped[0].name

        s = subast
        e.instance_exec() do
          @in = _in
          @what = what
          @_subast = s
          @type = type
          def self.subast
            @_subast[1].subast
          end
        end
        e.parented self
        e.build_str(ident)
      end
    end

    class RangeEach < Base
      include HasBody
      handles Q::Ast::MethodAddBlock, MethodAddBlock do
        next nil unless subast[0].is_a?(Q::Ast::Call)
        next nil unless subast[0].target.subast[0].is_a?(Q::Ast::Dot2)
        (subast[0].target.is_a?(Q::Ast::Paren)) and subast[0].call.symbol.to_s =~ /^each/
      end

      def initialize(*o)
        super
        mark_semicolon false
        mark_newline true
        mark_extra_newline true
      end
      
      def build_str ident = 0
Q.line = node.line
""

        e = For.allocate
        type = "int"
        _in = subast[0].target.subast[0]
        if subast[1].params.untyped[0]
          what = subast[1].params.untyped[0].name
        elsif prm=subast[1].params.typed[0]
          what = prm.name
          type = prm.type
        else
          Q::compile_error self, "no 'what'"
        end
        s = subast
        e.instance_exec() do
          @in = _in
          @what = what
          @_subast = s
          @type = type
          def self.subast
            @_subast[1].subast
          end
        end
     
        e.build_str(ident).gsub(/\;$/,'')
      end
    end
    
    class Paren < Base
      handles Q::Ast::Paren
    
      def parented par
        super
        subast.each do |c| c.parented self end 
      end
    
      def build_str ident = 0
Q.line = node.line
""

        if subast[0].node.flags[:type]
          "#{get_indent(ident)}typeof (#{subast[0].build_str}#{subast[0].is_a?(ArrayDeclaration) ? "[]" : ""})"

        else
          "(#{subast[0].build_str ident})"
        end
      end    
    end
        
    class ResolvedType
      attr_accessor :array, :type
      def initialize t, a=false
        @array = a


        if t.is_a?(ARef) and (t.of.is_a?(ConstPathRef) or (t.of.is_a?(Call) and (t.of.node.target.is_a?(Ast::ConstPathRef) or t.of.node.target.is_a?(Ast::SymbolLiteral))))

          if t.values
            @t=t=t.of.build_str+"<#{t.values.subast.map do |v| puts v.build_str;v.build_str end.join(", ")}>" 
          else
            @t=t=t.of.build_str+"[]"
          end
        end
     
        if t.is_a?(TypeType)
          t = t.target
        end
        
        if t
          t = t.to_sym if t.is_a?(::String)
          
          if t.is_a?(Q::Compiler::KnownType)
            if t.is_a?(ArrayDeclaration)
              @array = t
              @length = t.length
            end
            @type = t.get_type
            
            if t.is_a?(Type)
              @out = t.out?
              @ref = t.ref?
              @owned = t.owned?
              @unowned = t.unowned?
            end
          elsif t.is_a?(VarRef)
            if t.variable.is_a?(KeyWord)
              @type = case t.variable.symbol
              when :null
                :infered
              when :true
                :bool
              when :false
                :bool
              else
                :infered
              end
            else
              @type = t.variable.symbol
            end
          else
            @type = :infered
            
            @type = :'GLib.Type' if t.build_str =~ /^typeof\(.*\)$/
            #STDOUT.puts t
            @type = t.build_str if t.is_a?(Q::ValaSourceGenerator::VCall) rescue :infered
            qqq=t.build_str  if t.is_a?(Q::ValaSourceGenerator::Call)
            
            @type = t.build_str if t.is_a?(Q::ValaSourceGenerator::Call) and t.is_type? rescue :infered #and qqq=~/^[]/ rescue :infered
            @type = t.what.name.build_str+" "+t.target.build_str if t.is_a?(Q::ValaSourceGenerator::Call) and !is_type?(t) and t.what.name =~ /unowned|weak/
            @type = t.to_sym if t.respond_to?(:to_sym) and t.to_sym != :infered
            @type = @t.build_str.to_sym if is_type?(@t)
            if t.is_a?(Cast) 
              t.build_str =~ /\((.*?)\)/
              @type=$1
              def t.build_str ident=0
                what.build_str ident
              end if t.what.is_a?(Q::ValaSourceGenerator::Proc)
            end
            #STDOUT.puts @t.build_str
          end
        else
          
          @type = :infered

          @type = t.to_sym if t.respond_to?(:to_sym) and t.to_sym != :infered
        end
      end
      
      def infered?
        type == :infered
      end
      
      def out?
        @out
      end
      
      def ref?
        @ref
      end
      
      def owned?
        @owned
      end
      
      def unowned?
        @unowned
      end
      
      def nullable?
        if type.is_a?(::String)
          type = @type.to_sym
        end
        
        unless type
          return false
        end
        
        return true if type.get_type.to_s =~ /\?$/
      end
    end    
    
    class DeclaredType < ResolvedType
      attr_reader :name, :type, :array, :default
      attr_accessor :wrote
      def initialize n, t, a=nil, default: false
        @name = n
        @default = default
        @wrote = false
        super @t=t,a
      end
      
      def build_str ident = 0, p = nil
        Q.line = p.node.line if p
        ""

             # @type = @t  if @t
             
             name = self.name
             while p=p.parent
               if p.is_a?(HasModifiers)
                 if p.macro?
                   name = (p.macro_declares[name] ||= p.macro_vcall(name) )
                   break
                 end
               end
             end if p
             begin
               b = true if @t.node.inspect =~ /event\=\:symbol/
             rescue; end
        (" "*ident) + "#{out? ? "out " : "#{ref? ? "ref " : "#{ owned? ? "owned " : "#{unowned? ? "unowned " : ""}"}"}"}#{type}#{array ? "[]" : ""} #{name}"+
        ((default and !@t.is_a?(Type) and !@t.node.subast.flatten.index(:symbol) and !b) ? " = "+@t.build_str : "")
      end
    end
    
    class ConstPathRef < Base
      handles Q::Ast::ConstPathRef
      def initialize *o
        super
        if subast[0].is_a?(Type)
          extend Q::Compiler::KnownType
        end
      end
      
      def get_type
        build_str
      end
      
      def build_str ident = 0
        Q.line = node.line
        ""

        "#{get_indent(ident)}" +
        subast[0].build_str + "." +
        subast[1].symbol
      end
    end
    
    class Parameter < DeclaredType;
    end
    
    class Params < Base
      handles Q::Ast::Params
      
      attr_reader :typed, :untyped, :swarm
      def initialize n,t
        super n,t

        
        #STDOUT.puts node.inspect
        @typed = node.keywords.map do |n,t|
   
          tt = compiler.handle(t)
          tt= tt.node.value if tt.is_a?(StringLiteral)
          Parameter.new(compiler.handle(n).name, tt)
        end
        
        node.defaults.map do |n,t|
   
          tt = compiler.handle(t)
          #tt= tt.node.value if tt.is_a?(StringLiteral)
          @typed << p=Parameter.new(compiler.handle(n).name, tt, default:true)
 
        end
        
        @untyped = node.ordered.map do |n,t| 
          Parameter.new(n.name, nil)
        end  
        
        @swarm = node.swarm      
      end
      
      def parented *o
        super
        typed.each do |p| p.each do |t| t.parented self end end
        untyped.each do |p| p.each do |t| t.parented self end end
      end
    end
    
    class Label < Base
      handles Q::Ast::Label
      def name
        node.name
      end
    end
    
    class Symbol < Base
      handles Q::Ast::Symbol
      
      def symbol
        node.value
      end 
    end  

    class DynaSymbol < Base
      handles Q::Ast::DynaSymbol
      
      def symbol
        node.value
      end

      def build_str ident = 0
Q.line = node.line
""

        symbol.to_s
      end
    end  
    
    class SymbolContent < Base
      handles Q::Ast::SymbolContent
      
      def build_str ident = 0
Q.line = node.line
""


      end
    end 
    
    class StringEmbedExpr < Base
      handles Q::Ast::StringEmbedExpr
      
      def parented *o
        super
        parent.mark_template(true)
      end
      
      def build_str ident = 0
Q.line = node.line
""

        q=subast[0].build_str#, p: pp=parent.parent.parent.parent.parent.parent

        if pp.is_a?(Def)
         
          if pp.macro_declares.find do |qz, qx| qz == q end
          else;
            q=subast[0].build_str
          end
        end 

        if parent.is_a?(RawValaCode)
          "#{q}"
        else
          '$('+q+')'
        end
      end
    end

    class IfOp < Base
      handles Q::Ast::IfOp
      def build_str ident = 0
Q.line = node.line
""

        s=subast[0].build_str(ident)+" ? "+
        subast[1].build_str+" : "+
        subast[2].build_str
        #STDOUT.puts s
        s
      end
    end
    
    module Attribute
      class Value
        attr_accessor :default, :set, :get, :construct, :name, :value
        def initialize v, set = false, get = false, construct = nil
          @q = v
          @set = set
          @get = get
          @construct = construct
          @name = v.name
          
          if v.array and v.array.length
            @default = "new #{v.type}[#{v.array.length}]"
          end
        end
        
        def declare?
          @get != "get;" or @set != "set;"
        end
        
        def build_str ident = 0

""

          s=""
          if declare?()
            s="private #{@q.type}#{@q.array ? "[]" : ""} _#{@q.name};\n"
          end
          s+
          "#{" "*ident}public #{@q.type}#{@q.array ? "[]" : ""} #{@q.name} {"+
          "#{@get ? "#{@get}" : ""}"+
          "#{@set ? "#{@set}" : ""}"+
          "#{@construct ? "construct;" : ""}"+
          "#{@default ? "default = #{@default};" : ""}"+
          "}"
        end
        
        def q
          "#{@q.type}#{@q.array ? "[]" : ""}"
        end
      end
    
      include HasModifiers
      
      attr_accessor :set, :get, :construct
      def initialize *o
        super
        @values  = subast[1].subast[0].params.map do |v|
          Value.new(v,setter(v), getter(v), @construct)
        end
        
        mark_semicolon false
      end
      
      def parented *o
        q=super
        @values.each do |v|
          scope.add_property v.name, v
        end
        q
      end
      
      def build_str ident = 0
Q.line = node.line
""

        @values.map do |v| (" "*ident)+v.build_str(ident) end.join("\n")
      end
      
      def setter(v)
        if @set and @get
          return "set;"
        end
        
        if @set
          return "set { _#{v.name} = value;}"
        end
        
        return ""        
      end
      
      def getter(v)
        if @set and @get
          return "get;"
        end
        
        if @get
          return "get { return this._#{v.name};}"
        end
        
        return ""
      end
    end
    
    class AttrAcessor < Base
      include Attribute
      handles Q::Ast::Command, Command do
        subast[0].symbol.to_sym == :attr_accessor
      end
      def initialize *o
        @set = @get = true
        super        
      end
    end  
    
    class AttrWriter < Base
      include Attribute
      handles Q::Ast::Command, Command do
        subast[0].symbol.to_sym == :attr_writer
      end
      def initialize *o
        @set = true
        super        
      end
    end 
    
    class AttrReader < Base
      include Attribute
      handles Q::Ast::Command, Command do
        subast[0].symbol.to_sym == :attr_reader
      end
      def initialize *o
        @get = true
        super        
      end
    end

    class IfMod < Base
      handles Q::Ast::IfMod
      def initialize *o
        super
        mark_semicolon false
        mark_semicolon false
        mark_newline true
        mark_extra_newline true
      end
      
      def build_str ident = 0
Q.line = node.line
""

        "#{i=(" "*ident)}if (#{subast[0].build_str(0)}) {\n"+
        subast[1..-1].map do |c|
          c.parented(self)

          c.build_str(ident+2)+";"
        end.join("\n")+
        "\n#{i}}"
      end
    end       
    
    class Proc < Base
      handles Q::Ast::MethodAddBlock, MethodAddBlock do
        begin
          subast[0].subast[0].subast[0].symbol.to_sym == :proc
        rescue
          false
        end
      end
      
      def initialize *o
        o[0].instance_variable_set("@arguments",[o[0].subast.last])
        super *o
      end
      
      
      def build_str ident = 0
Q.line = node.line
""

        subast.map do |c|
          c.build_str(ident+2)
        end.join("\n")
      end
    end       
  end
end

