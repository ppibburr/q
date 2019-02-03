class Foo
  @prop = 12 #prop is :int
  attr_reader meef:int
  
  #knows string literal
  def foo() return "foo" end
  
  #knows int literal
  def bar() return 1 end
  
  #knows bool literal
  def quux() return true end
  
  #local vars type is know when type is set
  def obj()
    a = :Object
    a = Object.new()
    return a
  end
  
  #two pass body transpile
  #a knows g return type
  def a() return g() end
  
  #knows instance field type
  def baz() return @prop end
  
  #knows property type
  def meex() return @meef end
  
  #knows method type
  def g() return foo() end
  
  #knows casted type
  def cast() return :double > 8 end
  
  def test_uint_t(v:double) end

  
  def knows_inline_declare()
    a = :int > (5+6)
    return a
  end
  def knows_eqeq()
    return 5==5
  end
  def knows_assign_eqeq()
    b = 1==3
    return b
  end
  
  def knows_op_field()
    a = cast() + 4
    return a
  end
  
  def knows_op_lv()
    a = 1
    b = a + 1
    return b
  end
  
  def knows_rt_op_lv()
    a = 1
    return a+1
  end  
  
  def knows_rt_op_fld()
    return @meef+1
  end 
  
  def knows_arg(i: :int[])
    return i
  end  
  
  def knows_arg2(i:int)
    return i+4
  end
  
  def knows_lva()
    a = :int[0,1,2]
    return a
  end 
  
  @pa = :int[]
  def knows_pa()
    return @pa
  end  

  def knows_plva()
    a = @pa[0..2]
    return :int[] > a
  end  
  
  def self.t(a=4)
    return a
  end   
  
  def gg(u=true);
    return u
  end 
end


def quux() puts "hi" end

foo = Foo.new()
puts foo.foo()
puts foo.bar()
puts foo.obj().get_type() == typeof(:Object)
puts foo.baz()
puts foo.meex()
puts foo.g()
foo.test_uint_t(foo.cast())
puts foo.cast()
puts foo.gg()
quux()
