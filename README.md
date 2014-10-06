q
=

Ruby like syntax for Vala programming

Example
===
this ...

```ruby
class Foo < Object
  @name = :string
 
  def say_hello()
    print("%s says, Hi!\n", @name)
  end
  
  def self.new(n: :string?)
    base()
    @name = n
  end
end

def main(argv:string[])
  foo = Foo.new(argv[1])
  foo.say_hello()
end

```

becomes ...  

```vala
public class Foo : Object {
  public string name;

  public virtual void say_hello() {
    print("%s says, Hi!\n", this.name);
  }

  public Foo(string? n) {
    base();
    this.name = n;
  }
}

public void main(string[] argv) {
  var foo = new Foo(argv[1]);
  foo.say_hello();
}

```
