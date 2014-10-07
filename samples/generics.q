class Foo < Object
  generics T, U
  
  @t = :T
  @u = :U
  
  def sett(t:T):void
    @t = t
  end
  
  def gett():T
    return(@t)
  end
end

def main(argv:string[]):int
  foo = Foo[:int,:double?].new()
  
  foo.sett(5)
  foo.u = 5.0.d
  
  print("%d\n", foo.gett())
  print("%f\n", foo.u)
  
  return(0)
end
