Q
===
Ruby Syntax for Vala programming.  

Read the wiki!

Features
===
* implicit public vs vala's explicit
* regex match objects available with `$~, $1, ...`
* readability with: static, class and instance variables


Install
===
`rake gem`  
`sudo gem i pkg/*.gem`

USAGE
===
```
Q Compiler

Usage: valaq file [options] [-- [valac_options]]

    -v, --[no-]verbose               Run verbosely
        --introspection NAMESPACE-VERSION
                                     generate a gir: <NAMESPACE>-<VERSION>.gir
        --[no-]compile               compiles
        --[no-]remove-generated      Removes generated .vala files
    -V, --valac VALAC                specify the valac command
    -e, --exec                       execute after compiling
        --version                    show the version
    -h, --help                       Displays this summary

For valac options run 'valac --help'.
```

* Translation.  
This will generate `/some/source.vala`  
`valaq /some/source.q --no-compile`

* Translate and compile
This will generate `./source`  
`valaq /some/source.q [options] [valac_options]`

* multiple sources
```ruby
require "/some/other.q"
```

Sample
===
```ruby
class Example < Object
  # static  
  @@fld = :int
  @@fld2 = 55
  
  # instance
  @field  = :int
  @field2 = 6

  # properties: get; set;
  attr_accessor foo: :int[6], 
                bar: :string
  # properties: default = ...              
  @bar = "fred"

  attr_reader   baz:uint
  attr_writer   tree:string

  signal;
  def q(); end
 
  async;
  def x()
    # ...
  end
  
  def initialize()
    # constructor
  end
  
  def self.new()
    # Object(...)
  end
  
  # static
  def self.quux()
    # ...
  end
  
  # instance
  def moof()
    # ...
    q()
  end
end

def main(args: :string[])
  ex = Example.new()
  
  ex.q.connect() do
    print("moof!\n")
  end
  
  ex.moof()
end
```


Copyright
===
Copyright (c) 2014 ppibburr. See LICENSE.txt for
further details.

