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
    @path = File.expand_path(Q.src.split("\n")[ast.line-1].strip.gsub(/^require /,'').gsub(/'|"/,'').strip)
    @line = ast.line
    @source = Q.filename
  end
  
  def ok?
    File.exist?(path)
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
