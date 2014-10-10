class Foo < Object
  @al = :Gee::ArrayList[:int]
  
  delegate
  def iter_func(x:int):void; end
   
  def self.new(al:Gee::ArrayList[:int])
    @al = al
  end
  
  def append(x:int)
    @al.add(x)
  end
  
  def iter(x:iter_func):void
    @al.each(:int) do |i|
      x(i)
    end
  end
end

def main()
  al  = Gee::ArrayList[:int].new()
  foo = Foo.new(al)
  
  foo.append(1)
  foo.append(2)
  foo.append(3)
  
  foo.iter() do |i|
    print("%d\n",i)
  end
end
