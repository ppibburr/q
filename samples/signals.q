namespace Quux do
  class Foo < Object
    signal;
    def bar(); end
  
    signal;
    def quux(i:int); end
  
    @number = 5
  
    def moof()
      bar();
      quux(8)
    end
  end

  def main()
    foo = Foo.new()
  
    foo.bar.connect() do
      print("Signal closure called!\n")
    end
  
    foo.quux.connect() do |src, i|
      print("src.number: %d\ni: %d\n", src.number, i)
    end
    
    foo.quux.connect() do |i|
      print("And we can omit the source:\ni: %d\n",  i)
    end    
  
    foo.moof()
  end
end
