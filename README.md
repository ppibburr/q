Q
===

Install
===
`rake gem`  
`sudo gem i pkg/*.gem`

USAGE
===
* Translation.  
This will generate `/some/source.vala`  
`q2vala /some/source.q`

* Translate and compile
This will generate `./source`  
`valaq /some/source.q`

* multiple sources
```ruby
require "/some/other.q"
```

Sample
===
```ruby
class Person < Object
  # Construction properties
  property name: :string do
    get
    construct
  end
  
  property age: :int  do
    get
    construct set
  end
  
  def self.new(name: :string)
    Object(name: name)
  end

  def self.new_with_age(name: :string, years: :int)
    Object(name: name, age: years);
  end

  def initialize()
    # do anything else
    stdout.printf("Happy #{@age}, #{@name}!\n");
  end
end

def main(args: :string[])
  Person.new_with_age(args[1], :int.parse(args[2]))
end
```

becomes...  

```vala
public class Person : Object {
  public string name {
    get;
    construct;
  }

  public int age {
    get;
    construct set;
  }

  public Person (string name) {
    Object(name: name);
  }

  public Person.with_age (string name, int years) {
    Object(name: name, age: years);
  }

  construct {
    stdout.printf(@"Happy $(this.age), $(this.name)\n");
  }
}


public  void main(string[] args) {
  new Person.with_age(args[1], int.parse(args[2]));
}

```


Copyright
===
Copyright (c) 2014 ppibburr. See LICENSE.txt for
further details.

