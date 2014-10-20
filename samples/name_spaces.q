namespace NameSpaces do
  class Moof < {
    val:int,
    str:string
  }
  
    def baz():string
      return(@str)
    end
  end
    
  class Foo < Object
    @quux = 9
    
    property moof:Moof
      
    def bar():int
      return(7)
    end
  end
  
  def main(args:string[]):int
    foo = Foo.new()
    foo.moof = Moof() {
      val = args.length
      str = args[0]
    }
    
    print("#{foo.bar()}\n")
    
    return(0)
  end
end

