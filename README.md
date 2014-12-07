Q
===

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
      stdout.printf("Happy %d, %s!\n", @age, @name);
  end
end

def main(args: :string[])
  Person.new_with_age(args[1], :int.parse(args[2]))
end
```


Copyright
===
Copyright (c) 2014 ppibburr. See LICENSE.txt for
further details.

