class Foo < Object
  signal;
  def bar(); end
  
  signal;
  def quux(); end
  
  def moof()
    bar();
  end
end

def main()
  foo = Foo.new()
  
  foo.bar.connect() do
    print("Signal closure called!\n")
  end
  
  foo.moof()
end
