require File.join(File.dirname(__FILE__), "..", "ripper", "qsexp.rb")
$: << File.dirname(__FILE__)
module Q
  def self.compile_error w, m="compiler error ..."
    puts "#{w.node.line}, #{w.class}, #{w.node.event}"
    puts "#{m}";
    puts "#{src.split("\n")[w.node.line-1]}"
    exit(1)
  end
end
require "compiler"
require "ast"

class Q::Require
  attr_reader :path, :line, :source
  def initialize ast
    @line = ast.line
    @source = Q.filename
    @path = Q.src.split("\n")[ast.line-1].strip.gsub(/^require /,'').gsub(/'|"/,'').strip.split(";")[0]
  end
  
  def ok?
    if File.exist?(path)
      return true
    end

    if path == "Q"
      @path = File.join(File.dirname(__FILE__), "..", "std_macros.q")
      return true
    end

    if path =~ /^Q\/(.*)/
      pth = File.join(File.dirname(__FILE__), "..", $1)
      if File.exist?(pth)
        @path = pth
        return true
      end

      pth = File.join(File.dirname(__FILE__), "..", $1+".q")
      if File.exist?(pth)
        @path = pth
        return true
      end      
    end
    
    path = @path
    return true if File.exist?(@path=File.expand_path(@path))
    return true if File.exist?(@path=File.expand_path(File.join(File.dirname(Q.filename), path)))    
    return true if File.exist?(@path=File.expand_path(File.join("./", path)))
  end
end

class NilClass
  def build_str ident = 0
    ""
  end
end

class ::Symbol
  def get_type
    self
  end
end
