class Quux < Foo
  property bar: :int do get; set; end
  signal said_hello()
  
  def initialize()
    @year = 2015
  end
  
  def say_hello()
    super
    @bar = 69
    print("Hello from instance of Quux in #{@year}\n")
    said_hello()
  end
end
