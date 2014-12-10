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
      
      def initialize member
        @member = member
        @locals = {}
      end
      
      def append_lvar name, type
        @locals[name] = type
      end
      
      def declared?(name)
        if @locals[name]
          return true
        end
        
        if member.parent and member.parent.scope and member.parent.scope.declared?(name)
          true
        end
      end
      
      def get_lvar_type name
        raise "lvar #{name} not declared" unless type=declared?(name)
        if q=@locals[name]
          return q
        end
        
        if member.parent and member.parent.scope and member.parent.scope.declared?(name)
          member.parent.scope.get_lvar_type(name)
        end
      end
    end

    class StructScope < Scope
      def declared?(name)
        true
      end
    end

    class ProgramScope < Scope

    end

    class ClassScope < Scope

    end

    class MethodScope

    end

    class BlockScope

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
      rescue => e
        puts e
        puts e.backtrace.join("\n")
        Q.compile_error self
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
        (compiler.handlers[what] ||= []) << Handles::Handler.new(self,what, *overides, &b)
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
    
    def find_handler(node)
      a=self.class.handlers[node.class].find_all do |q| q.perform(node) end
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
      puts e
      Q.parse_error node.event, node.line
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
      
      end
    end
  end
end
