$: << File.join(File.dirname(__FILE__), "..")
require "base"

module Q
  class Compiler
    class Body
      def append_statement s
        @implicit_return_type = s.infer_return_type
      end
    end

    class Scope
      attr_reader  :member
      attr_accessor :in_macro
      
      def initialize member
        @member = member
        @locals = {}
      end
      
      def append_lvar name, type
        @locals[name] = type
      end

      def get_next_local
        @n ||= 0
        @n += 1
        "_q_local_#{@n}"
      end

      def sym
        s=[member.name] rescue []
        q=member
        while q and q.scope
          q = q.parent
          s << "#{q.name}" rescue ''
        end
    
        s.reverse.join("::")
      end
      
      def until_nil &b
        r = b.call(self)
 
        return self if r
        q = member
        while q and q.scope
          if r=b.call(q.scope)
            return q.scope
          end
          q = q.scope.member.parent
        end
      end
      
      def declared?(name)
        if @locals[name]
          return true
        end
        
        if member.parent and member.parent.scope and member.parent.scope.declared?(name)
          return true
        end
        
        if member.scope != self
          return member.scope.declared?(name)
        end
      end
      
      attr_accessor :locals
      def get_lvar_type name
        raise "lvar #{name} not declared" unless type=declared?(name)
        if q=@locals[name]
          return q
        end

        if member.parent and member.parent.scope and member.parent.scope.declared?(name)
          
          return member.parent.scope.get_lvar_type(name)
        end
      end
    end

    class StopLScope < Scope;end;

    class StructScope < StopLScope
      def declared?(name)
        true
      end
    end

    class ProgramScope < Scope

    end

    class ClassScope < StopLScope

    end

    class MethodScope < StopLScope

    end

    class BlockScope < Scope

    end 
 
    class Member;
      attr_reader :node, :compiler, :subast, :scope,:parent
      def to_s; self.class.to_s; end
      def inspect; self.class.to_s end
      def initialize node, compiler
        @node = node
        @compiler = compiler
        
        if @node.subast
          @subast = @node.subast.map do |a|
          if a.is_a?(Array)
           p a;exit
          end
            a.scope = get_childrens_scope
            compiler.handle(a)
          end
        else
          @subast = []
        end
        
        subast.each do |q| q.parented(self) end
      
      end
      
      def get_childrens_scope()
        scope
      end
      
      def parented parent
        @scope = parent.get_childrens_scope()
        @parent = parent
      end
      
      def self.compiler
        self::COMPILER
      end
      
      def self.handles what, *overides, &b
        unless what.is_a?(Array)
          (compiler.handlers[what] ||= []) << Handles::Handler.new(self,what, *overides, &b)
          return
        end

        what.each do |q|
        (compiler.handlers[q] ||= []) << Handles::Handler.new(self,q, *overides, &b)
        end
      end
    end
  
    attr_reader :ast
    def initialize ast
      @ast = ast    
    end
    
    def compile
    
    end
    
    # @param node [Q::Node]
    def handle node
      h = find_handler(node)
      h.new(node, self)
    end    
    
    def self.find_handler(node, bool=false)
      a=handlers[node.class].find_all do |q| q.perform(node) end
      marked = []
      a.each do |q|
        if a.find do |o| o.overides.index(q.klass) end
          marked << q
        end
      end
      
      marked.each do |q| a.delete(q) end
      
      klass = a.shift.klass

      raise unless klass
      
      return klass
    rescue => e
      if !bool
        puts e
        e.backtrace.each do |l| puts l end
        ev = node.event rescue "none #{node} #{node.class}"
        Q.parse_error ev, node.line
      end
      raise e    
    end
    
    def find_handler(node)
      self.class.find_handler(node)
    end
    
    class Handles
      class Handler
        attr_reader :klass, :what, :overides, :condition
        def initialize klass, what,*overide, &b
          @what       = what
          @overides   = overide
          @condition = b
          @klass = klass
        end
      
        def perform(node)
          if @condition
            return(node.class == what and node.instance_eval(&@condition.to_proc))
          else
            node.class == what
          end
        end
      end
    
      def initialize c
        @c = c
        @h = {}
      end
      
      def [] k
        @h[k] or (@c.superclass.respond_to?(:handlers) ? @c.superclass.handlers[k] : nil)
      end
      
      def []= k,v
        @h[k] = v
      end
    end
    
    def self.handlers
      @handlers ||= Handles.new(self)
    end
    
    module KnownType
      def get_type
        super
      rescue
      end
    end
  end
end
