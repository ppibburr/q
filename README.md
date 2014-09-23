q
=

Ruby like syntax for Vala programming

Example
===
```ruby
class MyLib < Object
  def hello():void
    print("Hello World, MyLib\n")
  end
  
  def sum(int:x, int:y):int
    return(x+y)
  end  
end

def main():int
  o = MyLib.new()
  o.hello()
  printf("%d\n",o.sum(3,3))
  return(0)
end

```

becomes

```vala
class MyLib : Object {
  public void hello () {
    stdout.printf("Hello World, MyLib\n");
  }

  public int sum (int x, int y) {
    return (x + y);
  }

}

public int main () {
  var o = new MyLib();
  o.hello();
  stdout.printf("%d\n",  o.sum(3,3));
  return (0);
}


```
