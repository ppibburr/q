module IFace
  def foo() :string
    return "foo"
  end
  
  abstract;def bar() :int; end
end

class Foo
  include IFace
  
  def bar() return 5 end
end


foo = Foo.new()
puts foo.foo()
puts foo.bar()
