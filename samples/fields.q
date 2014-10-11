class Foo < Object
  public
  @@s_fld = :int
  
  @i_fld = :int
  
  $c_fld = :int
  
  def initialize
    @@s_fld = 1
    $c_fld = 1
    @i_fld = 1
  end
  
  def print_c_fld()
    print("%d\n", $c_fld)
  end
end

def main()
  foo = Foo.new()
  foo.i_fld = 2
  Foo.s_fld = 2
  
  foo.print_c_fld()
  print("%d\n", foo.i_fld)
  print("%d\n", Foo.s_fld)  
end
