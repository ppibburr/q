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
