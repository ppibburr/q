$: << File.join(File.dirname(__FILE__), "..")
require "compiler"

module Q  
  class SourceGenerator < Compiler
    class Member < Compiler::Member
      def marked_semicolon?
        @mark_semicolon
      end
      
      def marked_newline?
        @mark_newline
      end
      
      def marked_extra_newline?
        @mark_extra_newline
      end      
      
      def marked_prepend_newline?
        @mark_prepend_newline
      end
      
      def mark_semicolon bool=true
        @mark_semicolon = bool
      end
      
      def mark_newline bool=true
        @mark_newline = bool
      end
      
      def mark_extra_newline bool=true
        @mark_extra_newline = bool
      end      
      
      def mark_prepend_newline bool=true
        @mark_prepend_newline = bool
      end
      
      def build_str ident = 0
      
      end      
    end
    
    def compile
      out = handle(@ast).build_str
      out
    end
  end
end
