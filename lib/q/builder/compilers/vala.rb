$: << File.dirname(__FILE__)
require "source_generator"

module Q
  class ValaSourceGenerator < Q::SourceGenerator
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
      COMPILER = Q::ValaSourceGenerator
      def initialize *o
        super
        mark_newline true
        mark_semicolon true
      end
      
      def get_indent ident
        " " * ident
      end
    end
  
    module HasModifiers
      MODIFIERS = [
        :public, :private, :static, :class, :delegate, :async, :virtual, :override, :abstract
      ]
    
      MODIFIERS.each do |m|
        define_method :"#{m}?" do
          @modifiers.index(m)
        end
        
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
      
      def initialize *o
        super
        @modifiers = []
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
        subast.map do |c| 
          (c.marked_prepend_newline? ? "\n" : "") +
          c.build_str(ident+2) +
          (c.marked_semicolon? ? ";" : "") +
          (c.marked_newline? ? "\n" : "") +
          (c.marked_extra_newline? ? "\n" : "")          
        end.join
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
        mark_semicolon false
        get_indent(ident) + subast[0].value.gsub(/^"/,'').gsub(/"$/,'')
      end 
    end
    
    
    class Array < Base
      handles Q::Ast::Array
      def members
        @members ||= node.members.map do |n| compiler.handle(n) end
      end
      
      def build_str ident = 0
        "{"+members.map do |m| m.build_str end.join(", ")+"}"
      end
    end
    
    class VarRef < Base
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
        variable.symbol
      end
      
      def build_str ident = 0
        get_indent(ident) + "#{kind == :instance ? "this." : ""}#{symbol.to_s}"
      end
    end
    
    class ARefField < Base
      handles Q::Ast::ARefField
      attr_reader :members
      def initialize *o
        super
        @what = compiler.handle(node.what)
        @members = node.members.map do |n| compiler.handle(n) end
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
        body.map do |s| s.build_str(ident+2) end.join(", ")
      end
    end
    
    class DelegateParameterDeclaration < Base
      handles Q::Ast::BareAssocHash
      attr_reader :params
      def initialize *o
        n = []
        for i in 0..o[0].subast.length-1
          n << o[0].subast.shift
        end
        
        super
        @params = n.map do |p|
          t = compiler.handle(p.value)

          Parameter.new(compiler.handle(p.label).name, t)
        end
      end
      
      def build_str ident = 0
        if !parent.parent.parent.parent.parent.parent.is_a?(Delegate)
          params.map do |p|
            p.name.to_s + ": " + p.type.to_s
          end.join(", ")
        else
          params.map do |p|
            p.type + " " + p.name.to_s
          end.join(", ")
        end
      end
    end
    
    class Command < Base
      handles Q::Ast::Command
      
      def build_str ident = 0
        t = get_indent(ident)
        if (s=subast[0].symbol) != "construct"
          "#{t}#{s}(#{subast[1].build_str})"
        else
          "#{t}#{s} #{subast[1].build_str}"
        end
      end
    end
    
    class Using < Base
      handles Q::Ast::Command, Command do
        subast[0].symbol.to_sym == :include
      end
      def build_str ident = 0
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
        subast[1].subast[0].subast[0].subast[1].subast[0].subast[0]
      rescue
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
        get_indent(ident) + "#{target} #{visibility} signal #{return_type ? return_type : :void} #{symbol}(#{params.build_str.gsub(":",'')})"
    
      end
    end 
    
    class Property < Base
      include DefaultMemberDeclaration
    
      handles Q::Ast::Command, Command do
        subast[0].is_a?(Q::Ast::Variable) and subast[0].symbol.to_sym == :property
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
        get_indent(ident) + 
        "#{visibility} #{target} #{type} #{symbol}"
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
        "#{kind} #{what.build_str}"
      end 
    end    
    
    class Program < Base
      handles Q::Ast::Program
      include HasBody
      def build_str ident = -2
        write_body(ident)
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
        @interfaces = subast[1].subast.map do |q| q.symbol end
      end
      
      
      
      def parented *o
        super
        parent.append_includes(self)
      end
      
      def build_str ident = 0; "p why?" ; end
    end

    module IFace
      attr_reader :name, :includes, :generics    
      include HasBody
      include DefaultMemberDeclaration      
      
      def initialize *o
        @includes = [] 
        super
      end
    
      def append_includes member
        member.interfaces.each do |i|
          next if includes.index(i)
          includes << i
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
        @childs_scope ||= Q::Compiler::ClassScope.new(self)
      end
      
      def build_str ident = 0
        "#{get_indent(ident)}#{visibility}#{iface_type ? " "+class_type : ""} interface #{name}#{do_inherit? ? " : #{inherits.join(", ")} " : " "}{\n"+
        write_body(ident)+
        "\n#{get_indent(ident)}}"
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
      end

      def get_childrens_scope
        @childs_scope ||= Q::Compiler::Scope.new(self)
      end
      
      def build_str ident = 0
        get_childrens_scope().append_lvar what.to_s, DeclaredType.new(what.to_s, :int)

        if self.in.is_a?(Q::Range)
          "#{get_indent(ident)}for (int #{what} = #{self.in.first}; #{what} <= #{self.in.last}; #{what}++) {\n" +
          write_body(ident)+
          "\n#{get_indent(ident)}}"
        else
          Q::compile_error self, "Must be Range"
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
          @super_class = compiler.handle(node.super_class).build_str
        end
        
        subast.map do |q| q.parented self end 
        
        mark_semicolon false
        mark_prepend_newline true
        mark_extra_newline
      end
      

      
      def get_childrens_scope
        @childs_scope ||= Q::Compiler::ClassScope.new(self)
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
        "#{get_indent(ident)}#{visibility}#{iface_type ? " "+class_type : ""} class #{name}#{do_inherit? ? " : #{inherits.join(", ")} " : " "}{\n"+
        write_body(ident)+
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
      
      def build_str ident = 0
        get_indent(ident) + @target.build_str + "." + what.symbol
      end
    end
    
    class ZSuper < Base
      handles Q::Ast::ZSuper
      def build_str ident = 0
        args = scope.member.params.typed.map do |p| p.name end.join(", ")
        get_indent(ident) + "base(#{args})"
      end
    end
    
    class Super < Base
      handles Q::Ast::Super
      def build_str ident = 0
        args = subast[0].build_str
        get_indent(ident) + "base(#{args})"
      end
    end    
    
    
    
    class ArgsAddBlock < Base
      handles Q::Ast::ArgsAddBlock
      
      def build_str ident = 0
        subast.map do |c| c.build_str end.join(", ")
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
        subast[1].is_a?(Type)
      end
      
      def assign_local ident=0
        Q::compile_error(self,"Cant assign local variable in #{scope.class}") unless scope and ![Q::Compiler::ClassScope].index(scope)
        
        if scope.declared?(variable.symbol)
          type = scope.get_lvar_type(variable.symbol)
        else
          # warn declaration by infered type
          if type = DeclaredType.new(variable.symbol, value) and !type.infered?
            return declare_field(type)+ "; " + assign_local
          else
            return declare_field(DeclaredType.new(variable.symbol, nil), ident)
          end
        end
 
        _new = ""
        
        "#{variable.symbol} = #{_new}#{value.build_str(ident).strip}"
      end
      
      def declare_field type = DeclaredType.new(symbol = variable.symbol, value), ident = 0
        scope.append_lvar type.name, type
        
        if type.infered?
          "var #{variable.symbol} = #{value.build_str(ident).strip}"
        else
          q = "#{type.build_str}" + 
          if type.array and type.array.length
            "; #{variable.symbol} = new #{type.type}[#{type.array.length}]"
          elsif type.nullable?
            " = null"
          else
            ""
          end
        end
      end

      def variable
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
          case variable.kind
          when :instance
           "#{get_indent(ident)}this."+variable.symbol + do_sets_field + " = #{value.build_str}"
          when :class
           "#{get_indent(ident)}"+variable.symbol + do_sets_field + " = #{value.build_str}"
          when :global
           "#{get_indent(ident)}"+variable.symbol + do_sets_field + " = #{value.build_str}"
          when :local
            if is_declaration?
              get_indent(ident) + declare_field
            else
              get_indent(ident) + assign_local(ident)
            end
          else
            raise "cant assign #{variable.kind}: #{variable.symbol}"
          end
      end
    end

    
    class Field < Assign

      handles Q::Ast::Assign, Assign do
        scope.is_a?(Q::Compiler::ClassScope) and :var_field == subast[0].event
      end
      
      include DefaultMemberDeclaration
      

      
      def build_str ident = 0
        return get_indent(ident) + case variable.kind
        when :constant
          "public const " + declare_field()
        when :class
          "public static "+declare_field()
        when :global
          "public class "+declare_field()
        when :instance
          "public "+declare_field()
        else
          raise "Bad Field"
        end
      end
        
      def declare_field type = DeclaredType.new(symbol = variable.symbol, value)
        if type.infered?
          raise "Cant infer field types: #{type.name}, #{type.type}"
        else
          if value.is_a?(Type)
            type.build_str +
            ((type.array and type.array.length) ? " = new #{type.type}[#{type.array.length}]" : "")
          elsif value.is_a?(Q::Compiler::KnownType)
            "#{type.build_str} = #{value.build_str}"
          elsif type.type == :bool
            "#{type.build_str} = #{value.build_str}"
          else
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
      
      def of
        @of ||= compiler.handle(node.of)
      end
      
      def values
        @values ||= compiler.handle(node.values)
      end
      
      def build_str ident=0
        if of.is_a?(DeclaredType)
        "#{of.get_type}[]"
        else
          of.build_str+
          "[#{values.build_str}]"
        end
      end
    end

        

    class Type < Base
      include Q::Compiler::KnownType
      handles Q::Ast::SymbolLiteral
      
      def value
        subast[0].symbol
      end
      
      def get_type
        value
      end
      
      def build_str ident = 0
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
      
      def build_str ident = 0
        if left.is_a?(VarField)
          l = left.variable.symbol
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
      handles Q::Ast::ARef, ARef do
        of.is_a?(Q::Ast::SymbolLiteral) or of.is_a?(Q::Ast::ARef)
      end
      
      attr_reader :of, :length
      def initialize *o
        super
        @of = compiler.handle(node.of)
     
        @length = node.values.subast.map do |n| compiler.handle(n) end[0].node.value if node.values
      end
      
      def value
        of.get_type
      end
      
      def get_type
        of.get_type
      end
    end

    module GenericsType
      attr_reader :iface, :types
      def initialize *o
        super
        @iface = compiler.handle(node.of).build_str
        @types = node.values.subast.map do |n| compiler.handle(n).get_type end
      end
      
      def build_str ident = 0
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
      include GenericsType
      include Q::Compiler::KnownType
      handles Q::Ast::ARef, ARef, ArrayDeclaration do
        of.is_a?(Q::Ast::SymbolLiteral) and values and values.subast[0] and values.subast[0].is_a?(Q::Ast::SymbolLiteral)
      end
    end 
    
    class VCall < Base
      handles Q::Ast::VCall
      
      def build_str ident = 0
        get_indent(ident) + subast[0].symbol
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
        node.value.to_s + 
        case get_type
        when :float
          "f"
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

        "#{get_indent(ident)}#{target.build_str.gsub(/f|d$/,'')}#{type.to_s[0]}"
      end
    end  
    
    class Return < Base
      handles Q::Ast::Return
      def build_str ident = 0
        get_indent(ident) + "return (#{subast[0].build_str()})"
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
        subast[0].build_str ident
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
        p node.value
      end
      
      def build_str ident = 0
        value
      end   
    end
    
    class Def < Base
      include HasBody
      include DefaultMemberDeclaration
      handles Q::Ast::Def

      attr_reader :params, :return_type
      def initialize *o
        super
        
        @params = compiler.handle(node.params)
        if subast[0].is_a?(Type)
          @return_type = ResolvedType.new(subast.shift)
        end
        
        mark_prepend_newline true
        mark_semicolon false
        mark_newline true
      end
 
      def symbol
        node.symbol.symbol
      end
      
      def get_childrens_scope
        @childs_scope ||= Q::Compiler::Scope.new(self)
      end
     
      def build_str ident = 0
        plist = params.typed.reverse.map do |p| p.build_str end
        
        params.typed.reverse.each_with_index do |p,i|
          if p.nullable?
            plist[i] = plist[i] + " = null"
          else
            break
          end
        end
        
        rt = return_type ? return_type.type : :void
        
        ret = return_type and return_type.nullable?
        if ret
          if !subast.find do |q| q.is_a?(Return) end
            ret = "\n\n#{get_indent(ident+2)}return null;"
          else
            ret = ""
          end
        else
          ret = ""
        end
        
        kind = self.kind
        visibility = self.visibility
        async = self.async
        bool = false
        
        symbol = self.symbol
        
        if symbol.to_sym == :initialize
          rt = ""
          symbol = :construct
          kind = ""
          async = ""
          visibility = ""
          bool = true
        end
        
        "#{get_indent(ident)}#{target} #{visibility} #{async}#{kind} #{rt} #{symbol}#{symbol == :construct ? "" :"(#{plist.reverse.join(", ")})"} {\n" +
        write_body(ident) +
        ret +
        "\n#{get_indent(ident)}}"
      end
      
      def kind
        scope.is_a?(Q::Compiler::ClassScope) ? " virtual" : ""
      end
    end  
    
    class Binary < Base
      handles Q::Ast::Binary
      attr_reader :right, :left, :operand
      def initialize *o
        super
        @left, @operand, @right = [compiler.handle(node.left), node.operand, compiler.handle(node.right)]
      end
      
      def build_str(ident = 0)
        "#{get_indent(ident)}#{left.build_str} #{operand} #{right.build_str}"
      end
    end
    
    class Cast < Base
      handles Q::Ast::Binary, Binary do
        left.is_a?(Q::Ast::SymbolLiteral) and operand.to_sym == :"<<"
      end
      
      attr_reader :to, :what
      def initialize *o
        super
        @to = compiler.handle(node.left)
        @what = compiler.handle(node.right)
      end
      
      def build_str ident = 0
        case to.build_str.strip
        when "out"
          "#{to.build_str} #{what.build_str}"
        when "ref"
          "#{to.build_str} #{what.build_str}"
        else
          "(#{to.build_str})#{what.build_str}"
        end
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
        @else.parented self if @else
      end
      
      def build_str ident = 0
        if self.class == Q::ValaSourceGenerator::If
          mark_prepend_newline true
        end
        
        (t=get_indent(ident)) +
        "#{type.to_s.gsub("elsif", "else if")} (#{exp.build_str}) {\n"+
        write_body(ident)+
        "\n#{t}}" +
        (self.else ? "\n"+self.else.build_str(ident) : "")
      end      
    end
    
    class ElsIf < If
      handles Q::Ast::ElsIf
      def initialize *o
        super
        @type = :elsif
      end
    end
    
    class Else < Base
      include HasBody
      handles Q::Ast::Else
      
      def build_str ident = 0
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
        @exp.parented self      
      end
      
      def build_str ident = 0
        (t=get_indent(ident)) +
        "while (#{exp.build_str}) {\n"+
        write_body(ident)+
        "\n#{t}}"
      end
    end
    
    class Singleton < Base
      handles Q::Ast::DefS
      include HasBody
      include HasBody
      include DefaultMemberDeclaration
      
      attr_accessor :symbol, :params, :return_type
      def initialize *o
        super
        
        @symbol = node.symbol.symbol
        @params = compiler.handle(node.params)
        
        @subast = node.body.subast[0].children.map do |c| compiler.handle(c) end
        @subast.each do |c| c.parented self end
        
        if subast[0].is_a?(Type)
          @return_type = DeclaredType.new(subast.shift)
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
        @childs_scope ||= Q::Compiler::Scope.new(self)
      end
      
      def build_str ident = 0
        plist = params.typed.reverse.map do |p| p.build_str end
        
        params.typed.reverse.each_with_index do |p,i|
          if p.nullable?
            plist[i] = plist[i] + " = null"
          else
            break
          end
        end      
      
        rt = return_type ? return_type.get_type : :void

      
        if !static_construct? and !constructor?
          sig = "#{visibility} static #{rt} "+symbol+"(#{plist.reverse.join(", ")}) {\n"
        elsif static_construct?
          sig = "static construct {\n"
        elsif constructor?
          q = ""
          
          if symbol.to_s != "new"
            q = ".#{symbol.to_s.gsub(/^new\_/,'')}"
          end
          
          sig = "#{visibility} #{scope.member.name}#{q} (#{plist.reverse.join(", ")}) {\n"
        end
        
        get_indent(ident) + 
        sig +
        write_body(ident) +
        "\n#{get_indent(ident)}}"
      end
    end
    
    class MethodAddBlock < Base
      handles Q::Ast::MethodAddBlock
      def build_str ident = 0
        args = subast[0].subast[1].subast[0] ? subast[0].subast[1].subast[0].subast.length : 0
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
      
      def build_str ident = 0
        mark_semicolon false
        mark_newline true
     
        mark_prepend_newline true
        (t = get_indent(ident)) +
        subast.shift.build_str(ident) +
        " {\n" +
        write_body(ident).gsub(/\(.*\=\> \{/, '').gsub(/\};\n$/,"}\n")
      end
    end      
    
    class StructNew < MethodAddBlock
      handles Q::Ast::MethodAddBlock, MethodAddBlock do
        subast[1].class == Q::Ast::BraceBlock
      end
      
      def build_str ident = 0
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
        "(#{params ? params.untyped.map do |p| p.name end.join(", ") : ""}) => {\n" +
        write_body(ident) + 
        "\n#{get_indent(ident)}}"
      end
      
      def get_childrens_scope
        if r=@childs_scope
         return r
        end
        r =@childs_scope = Q::Compiler::Scope.new(self)
        
        return r
      end
    end
    
    class MethodAddArg < Base
      handles Q::Ast::MethodAddArg
      
      def build_str ident = 0
        get_indent(ident) + subast[0].build_str +
        "(" +
        (subast[1] ? subast[1].build_str : "") +
        ")"
      end
    end
    
    class ArgParen < Base
      handles Q::Ast::ArgParen
      
      def build_str ident = 0
        subast[0] ? subast[0].build_str : ""
      end
    end    
    
    class FCall < Base
      handles Q::Ast::FCall
      
      def build_str ident = 0
        subast[0].symbol
      end
    end    
   

    
    class ObjectNew < Base
      handles Q::Ast::MethodAddArg, MethodAddArg do
        subast[0].is_a?(Q::Ast::Call) and (subast[0].target.is_a?(Q::Ast::ARef)  or (subast[0].target.subast[0].respond_to?(:kind) and subast[0].target.subast[0].kind == :constant)) and subast[0].call.symbol.to_s =~ /^new/
      end
      
      def build_str ident = 0
      method = ""
      
      if subast[0].what.symbol.to_sym != :new
        method = "." +
        "#{subast[0].what.symbol}".gsub(/^new\_/,'')
      end
        "new #{subast[0].target.symbol}#{method}(#{subast[1].build_str})"
      end
    end    

    class TypeType < Base
      handles Q::Ast::Call, Call do;
        target.is_a?(Q::Ast::SymbolLiteral) and (call.symbol.to_s =~ /^ref$/ or call.symbol.to_s =~ /^out$/ or call.symbol.to_s =~ /^(unowned|owned)/)
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
        i = par.subast.index(self)
        par.subast[i] = target
        target.parented par
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
        get_childrens_scope().append_lvar var_name.to_sym, DeclaredType.new(var_name.to_sym, type.to_sym)
        
        "#{get_indent(ident)}foreach (#{type} #{var_name} in #{array})"+
        subast[1].build_str(ident).gsub(/^\(.*\=\> \{/, " {")
      end
      
      def get_childrens_scope
        @childs_scope ||= Q::Compiler::Scope.new(self)
      end
    end

    class RangeEach < Base
      include HasBody
      handles Q::Ast::MethodAddBlock, MethodAddBlock do
        next nil unless subast[0].is_a?(Q::Ast::Call)
        next nil unless subast[0].target.subast[0].is_a?(Q::Ast::Dot2)
        (subast[0].target.is_a?(Q::Ast::Paren)) and subast[0].call.symbol.to_s =~ /^each/
      end
      
      def build_str ident = 0
        e = For.allocate
        _in = subast[0].target.subast[0]
        what = subast[1].params.untyped[0].name
        s = subast
        e.instance_exec(_in, what, s) do
          @in = _in
          @what = what
          @_subast = s
          def self.subast
            @_subast[1].subast
          end
        end
        e.build_str(ident)
      end
    end
    
    class Paren < Base
      handles Q::Ast::Paren
    
      def build_str ident = 0
        subast[0].build_str ident
      end    
    end
        
    class ResolvedType
      attr_accessor :array, :type
      def initialize t, a=false
        @array = a
        
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
          end
        else
          @type = :infered
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
      attr_reader :name, :type, :array
      def initialize n, t, a=nil
        @name = n
        t = t.to_sym if t.is_a?(::String)
        super t,a
      end
      
      def build_str ident = 0
        (" "*ident) + "#{out? ? "out " : "#{ref? ? "ref " : "#{ owned? ? "owned " : "#{unowned? ? "unowned " : ""}"}"}"}#{type}#{array ? "[]" : ""} #{name}"
      end
    end
    
    class Parameter < DeclaredType;
    end
    
    class Params < Base
      handles Q::Ast::Params
      
      attr_reader :typed, :untyped
      def initialize *o
        super
        @typed = node.keywords.map do |n,t| 
          tt = compiler.handle(t)

          Parameter.new(compiler.handle(n).name, tt)
        end
        
        @untyped = node.ordered.map do |n,t| 
          Parameter.new(n.name, nil)
        end        
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
    
    class SymbolContent < Base
      handles Q::Ast::SymbolContent
      
      def build_str ident = 0

      end
    end 
    
    class StringEmbedExpr < Base
      handles Q::Ast::StringEmbedExpr
      
      def parented *o
        super
        parent.mark_template(true)
      end
      
      def build_str ident = 0
        '$('+subast[0].build_str+')'
      end
    end 
  end
end