module Q
  module Ast
    def self.find_for event, *foo
      q = Node.q_map.find_all do |t,b|
        if b.arity == 0
          event == b.call()
        else
          b.call(event, *foo)
        end
      end.first
      
      if q
        puts "Have #{q[0]}"
        return q[0]
      end
      
      puts "TODO: Unhandled #{event} #{foo}"
      
      return nil
    end
    
    def self.set_flags w,*flags
      flags.each do |f| w.flags[f] = true end
    end


    class Node  
      attr_accessor :parent, :line, :scope, :flags
      
      def self.register &b
        (@@q_map ||= {})[self] = b
      end
      
      def self.q_map
        @@q_map ||= {}
      end
      
      def parented parent
        @parent = parent
      end
      
      def initialize l
        @line = l
        @flags = {}
      end
      
      def build_str ident=0
        raise "#{line} NotImplemented"
      end
    end



    class Comment < Node
      register do
        :"@comment"
      end
      attr_reader :value
      def initialize e,l, *o
        @value = o[0].strip.gsub(/^\#/,'')
        super l
        Q::COMMENTS[l] = self
      end
    end

    class Event < Node
      attr_accessor :event
      def initialize event, line
        @event = event
        super line
      end
      
      def subast
        []
      end
    end

    module HasBlock
      def initialize *o
        super
      end
    end

    module HasArguments
      attr_accessor :arguments
      def initialize event, line, *o
        @arguments = o
        super event, line
      end
      
      def push item
        @arguments << item
      end
      
      def subast
        arguments
      end
    end

    class Dot2 < Event
      register do :dot2 end
      attr_accessor :first, :last
      include HasArguments
      def initialize *o
        super
        @first = subast.shift
        @last = subast.shift
      end
    end

    class Array < Event
      attr_reader :members
      include HasArguments
      register do :array end
      def initialize *o
        super
        @members = subast.shift.children
      end
    end
    
    class StringEmbedExpr < Event
      include HasArguments
      register do :string_embexpr end
      def initialize *o
        super
      end
      
      def subast
        super[0].children
      end
    end
    
    class Return < Event
      include HasArguments
      register do :return end
    end
    
    class Return0 < Event
      include HasArguments
      register do :return0 end
    end    
    
    class Next < Event
      include HasArguments
      register do :next end
    end    
    
    class VarRef < Event
      include HasArguments
      register do :var_ref end
      def variable
        subast[0]
      end
    end
    
    class ARefField < Event
      attr_reader :members, :what
      include HasArguments
      register do :aref_field end
      def initialize *o
        super
        @what = subast.shift
        @members = subast.shift.subast
        def self.subast
          []
        end
      end
    end

    class AssocNew < Event
      include HasArguments
      register do :assoc_new end
      attr_reader :label, :value
      def initialize *o
        super
        @label = subast.shift
        @value = subast.shift
      end
    end
    
    class BareAssocHash < Event
      include HasArguments
      register do :bare_assoc_hash end
      def subast
        super[0]
      end
    end    
    
    class BraceBlock < Event
      include HasArguments
      register do :brace_block end
    
      attr_reader :params, :body
      def initialize *o
        super
        @params = subast.shift
        @body = subast.shift
      end
    end

    class Command < Event
      include HasArguments
      register do :command end
      def initialize *o
        super

        if subast[0].symbol.to_sym == :require;
          def self.parented par
            par.requires << Q::Require.new(self)
          end
        end
      end
    end
    
    class Begin < Event
      include HasArguments
      register do :begin end
      attr_reader :else, :ensure, :rescue
      def initialize *o
        super

        @ensure = subast.pop
        @else   = subast.pop
        @rescue = subast.pop    
        @body = subast.pop.children            
      end
      
      def subast
        p @body
        @body || super[0].subast
      end
    end
    
    class Rescue < Event
      include HasArguments
      register do :rescue end
      attr_reader :what, :variable, :next_rescue
      def initialize *o
        super
        @what        = subast.shift
        @variable    = subast.shift
        @next_rescue = subast.pop
        @body        = subast[0].children
      end
      
      def subast
        p @body
        @body || super
      end
    end
    
    class Retry < Event
      include HasArguments
      register do :retry end
      def initialize *o
        super

      end
    end    
    
    class Ensure < Event
      include HasArguments
      register do :ensure end
      def initialize *o
        super
      end
      def subast
        super[0].children
      end
    end    
    
    class RegexpEnd < Event
      include HasArguments
      register do :"@regexp_end" end
      attr_reader :value
      
      def initialize *o
        @value = o[2].gsub(/^\//,'') if o[2]
        super
      end
    end

    class Regexp < Event
      include HasArguments
      register do :regexp_literal end
      attr_reader :value, :modifier
      def initialize *o
        super
       
        @value = subast.shift.children[0].value
        @modifier = subast.shift.value
        def self.subast
          []
        end
      end
    end

    class Field < Event
      include HasArguments
      register do :field end
      def initialize *o
        super
        subast.delete_at(1)
      end
    end

    class Unary < Event
      include HasArguments
      attr_reader :kind, :what
      register do :unary end
      def initialize *o
        super
        @kind = subast.shift
        @what = subast.shift
      end
    end

    class Variable < Event
      include HasArguments
      register do |q|
        [:'@ident', :'@const', :'@gvar', :'@cvar', :'@ivar', :'@backref'].index(q)
      end
      
      attr_accessor :name
      
      def initialize *o
        super
        @name = arguments.shift
      end
      
      def symbol
        name.to_s.gsub(/^\@\@/,'').gsub(/^\@/,'').gsub(/^\$/,'')
      end
      
      def kind
        case event
        when :'@ident'
          :local
        when :'@const'
          :constant
        when :'@gvar'
          :global
        when :"@cvar"
          :class
        when :"@ivar"
          :instance
        when :"@backref"
          :backref
        end
      end
    end

    class XStringLiteral < Event
      include HasArguments
      register do
        :xstring_literal
      end
      def subast
        super[0].children
      end
    end
    
    class StringContent < Event
      include HasArguments
      register do
        :string_content
      end
    end
    
    class StringLiteral < Event
      include HasArguments
      register do
        :string_literal
      end
    end 
    
    class TStringContent < Event
      include HasArguments
      register do
        :'@tstring_content'
      end
      
      attr_reader :value
      def initialize *o
        super
        @value = arguments.shift
      end      
    end           

    class MethodAddArg < Event
     include HasArguments
     
     register do :method_add_arg end
    end
    
    class DoBlock < Event
      include HasArguments
      register do :do_block end
      attr_reader :params
      def initialize *o
       super
       t = @arguments.shift
       @params = t ? t.params : nil
      end
      def subast
        super[0].children
      end
    end
    
    class DefS < Event
     include HasArguments
     register do :defs end
     
     attr_accessor :what, :symbol, :params, :body
     def initialize *o
      super
      @what = subast.shift
      subast.shift
      @symbol = subast.shift
      @params = subast.shift.subast[0]
      @body = subast.shift
      @arguments = []
     end
    end
    
    class BlockVar < Event
      include HasArguments
      register do :block_var end
      attr_reader :params
      def initialize *o
       super
       @params = subast.shift
      end
    end
    
    class MethodAddBlock < Event
      include HasArguments
      register do :method_add_block end
    end

    class ArgParen < Event
     include HasArguments
     
     register do :arg_paren end
     def subast
       q = super()
       if q and q.length == 1 and !q[0]
         []
       elsif q
         q
       else
         []
       end
     end
    end
    
    class FCall < Event
      include HasArguments
      register do :fcall end
    end

    class Numerical < Event
      register do |q|
        [:'@float', :'@int'].index(q)
      end

      attr_accessor :type
      attr_accessor :value
      
      def initialize event, line, *o
        @value = o[0]
        super event, line
        @type = event.to_s.gsub("@",'').to_sym
      end
    end

    class VarField < Event
      register do
        :var_field  
      end
      include HasArguments
      def initialize *o
        super
        @variable = arguments.shift
      end
      
      def variable
        @variable
      end
    end

    class Assign < Event
      include HasArguments
      register do
        :assign
      end
    end


    class Program < Event
      include HasArguments
      register do
        :program
      end
      
      attr_reader :requires
      def initialize *o
        super
        @statements = arguments.shift
        @requires = []
      end
      
      def subast
        @statements.children
      end
      
      def parented *o
        super   
        subast.each do |c| c.parented self end
      end
    end

    class Statements < Node
      attr_reader :children
      def initialize *o
        @children = []
        super
      end
      
      def parented parent = nil
        children.each do |c| c.parented(parent) if c end 
        super(parent)
      end
      
      def push item
        @children << item
      end
      
      def subast
        children
      end
    end

    class BodyStmt < Event
      include HasArguments
      register do
        :bodystmt
      end
    end

    class Klass < Event
      include HasArguments
      register do
        :class
      end
      
      attr_reader :super_class
      
      def initialize event, line, *o
        super event, line, *o
        @name = @arguments.shift
        @super_class = @arguments.shift
      end
      
      def subast
        arguments[0].arguments[0].children
      end
      
      def name
        @name.value
      end
    end

    class Call < Event
      include HasArguments

      register do
        :call
      end
      
      attr_reader :call, :q, :target
      def initialize *o
        super
        @target = subast.shift
        @q = subast.shift
        @call = subast.shift
      end
      
    end

    class ARef < Event
      include HasArguments

      register do
        :aref
      end
      
      
      attr_reader :of, :values
      def initialize *o
        super
        @of = subast.shift
        @values = subast.shift
      end
    end
    
    class ArgsAddBlock < Event
      register do :args_add_block end
      
      include HasArguments
      
      def subast
        super()[0].children
      end
    end
    
    class ConstPathRef < Event
      include HasArguments

      register do
        :const_path_ref
      end
    end

    class OP < Event
      include HasArguments
      register do :"@op" end
      attr_reader :kind
      def initialize *o
        super
        @kind = subast.shift
      end
    end

    class ZSuper < Event
      register do :zsuper end
    end
    
    class Super < Event
      include HasArguments
      register do :super end
    end  
    
    class If < Event
      include HasArguments
      register do :if end
      attr_reader :exp, :type, :else
      def initialize *o
        super
        @type = :if
        @exp = subast.shift
        @else = subast.pop
        def self.subast
          super[0].children
        end
      end
    end
    
    class ElsIf < If
      register do :elsif end
      def type; :elsif; end
    end
    
    class Else < Event
      include HasArguments
     
      register do :else end
      def subast
        super[0].children
      end
    end

    class While < Event
      include HasArguments
      register do :while end
      attr_reader :exp
      def initialize *o
        super

        @exp = subast.shift

        def self.subast
          super[0].children
        end
      end
    end
    
    class Binary < Event
      include HasArguments
      register do :binary end
      
      attr_reader :operand, :left, :right
      def initialize *o
        super
        
        @left    = subast.shift
        @operand = subast.shift
        @right   = subast.shift
      end
    end  

    class KeyWord < Event
      include HasArguments
      register do :"@kw" end
      attr_reader :value
      def initialize *o
        super
        @value = subast.shift.to_sym
      end
    end

    class OPAssign < Event
      include HasArguments

      register do
        :opassign
      end
      
      attr_accessor :left, :op, :right
      def initialize *o
        super
        
        @left  = subast.shift
        @op    = subast.shift
        @right = subast.shift
      end
    end

    class Symbol < Event
      include HasArguments

      register do
        :symbol
      end
      attr_reader :value
      def initialize *o
        super
        @value = arguments.pop.symbol
      end
    end

    class ConstRef < Event
      include HasArguments

      register do
        :const_ref
      end
      
      def value
        arguments[0].name
      end
    end

    class VCall < Event
      include HasArguments
      register do
        :vcall
      end
    end
    
    class Params < Event
      include HasArguments
      register do
        :params
      end
      
      attr_reader :ordered, :keywords, :defaults, :swarm
      def initialize *o
        super
        @ordered = arguments.shift || []
        _ = arguments.shift
        _ = arguments.shift
        _ = arguments.shift
        @keywords = arguments.shift || []
        @arguments = []
      end
      
      def parented *o
        super
        ordered.each do |q| q.each do |t| t.parented parent end end
        defaults.each do |q| q.each do |t| t.parented parent end end        
      end
    end
    
    class Paren < Event
      include HasArguments
      register do
        :paren
      end
      
      def subast
        q = super()
        q[0].respond_to?(:children) ? q[0].children : q
      end
      
      def build_str ident = 0
        ""
      end
    end
    
    class SymbolContent < Event
      include HasArguments
      register do
        :symbol_content
      end
    end   
    
    class SymbolLiteral < Event
      include HasArguments
      register do
        :symbol_literal
      end
    end      

    class Label < Event
      include HasArguments
      register do
        :'@label'
      end
      attr_reader :name
      def initialize *o
        super
        @name = arguments.shift.gsub(":", '')
      end
    end
    
    class VoidStmt < Event
      register do
        :void_stmt
      end
    end   
    
    class For < Event
      include HasArguments
      register do :for end
      attr_reader :what, :in
      
      def initialize *o
        super *o
        @what = subast.shift.variable.symbol
        @in = subast.shift
      
        def self.subast
          super[0].children
        end
      end
    end
    
    class Module < Event
      include HasArguments
      register do :module end
    
      attr_reader :symbol
      def initialize *o
        super
        @symbol = arguments.shift.subast[0].symbol
      end
    
      def subast
        super()[0].arguments[0].children      
      end
      
      def name
        symbol
      end
    end
    
    class Def < Event
      include HasArguments
      register do
        :def
      end
      
      attr_reader :symbol, :params
      def initialize *o
        super
        @symbol = arguments.shift
        @params = arguments.shift.subast[0]
      end
      
      def subast
        super()[0].arguments[0].children      
      end
    end

    class << self
      attr_accessor :compiler_type
    end

    def self.handle_has_arguments event, line, *args
      n = find_for(event, *args).new(event, line, *args)
      if compiler_type
        begin
          if c=compiler_type.find_handler(n,true)
            set_flags n, c::FLAG
          end
        rescue
        end
      end
      return n
    rescue => e
      puts e
      Q.parse_error event,line      
    end
    
    def self.handle_single event, line, *foo
      find_for(event, *foo).new(event, line, *foo)
    rescue

    end 
    
    def Q.parse_error event, line
      puts "#{line}, unsupported #{event}."
      puts "#{src.split("\n")[line-1]}"
      exit(1)
    end 
  end
end
