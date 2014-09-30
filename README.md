q
=

Ruby like syntax for Vala programming

Proposed translation
===
```ruby
# $<name>   class field
# @@<name>  static field
# @<name>   instance field
# <name>    local

# Declaring explicit types
#
# n   = :int                 # int name;
# n   = :int[]               # int[] name;
# n   = :int[4]              # int[] name = new int[4];
# n   = :"ArrayList<string>" # ArrayList<string> name = new ArrayList<string> ();

# Local inference
#
# scope does not have 'a' as a local var
# a = 1         # var a = 1;
# a = int[4]    # var a = new int[4];
# a = [1,2,3,4] # raise "Arrays must be explicty typed"
#
# if a is in local scope ...
#
# a = [1,2,3]   # a = {1,2,3};


namespace :N do
# namespace N { ... }

  module Foo [Object, Bar]
  # interface Foo : Object, Bar {
  #   ...
  # }
  end

  class N < Object
    include Foo
    # pubic class N : Object, Foo { ... }



    # static field
    #
    # [public | protected (| private)] 
    @@foo = :int[4] # {type:value}
    #=> private static int[] foo = new int[4]; 
    
    # static property
    #
    # [public | private (| protected)]
    sattr_accessor :bar, :int # [| type:<value>] 
    #=> protected static int bar { get;set; /* default = <value> */}


    # class field
    # 
    # [private (| protected)] 
    $foo = :int[4] 
    #=> protected class int[] foo = new int[4];
    
    # class property
    #
    # [private (| protected)]
    cattr_accessor :bar, :int 
    #=> protected class int bar { get;set; /* default = <value> */}

    # instance field
    #
    # [public (| private)]
    @foo = :int[4] # | type:<value>
    
    # instance property
    #
    # [private (| public)]
    attr_accessor :ins_p, :int[4]    
    #=> public int[] ins_p { get;set; default = new int[4];}
    
    class << self
      # static construct { ... }
      @@foo[0] = 1;
    end
    
    def self.inherited
      # class construct { ... {
      # $foo[0] = 1;
    end
    
    def self.new
      # public Type() { ... }
    end
    
    def self.new_with_property(prop:int)
      # public Type.with_property(int prop) { ... }
    end
    
    def initialize
      # construct { ... }
    end
    
    delagate
    def del(a:int[]):void
      # delegate void public del (int[] a) { }
    end
    
    def d(a:int[], b:del):void
      b(a);
      # public void d (int a, del b) {
      #   b(a);
      # }
    end
    
    # [override | new | abstract (| virtual | public)]
    # NOTE: abstract for interfaces, abstract class's
    def self.bar():void
      # static public void bar() { ... }
    end
    
    # [override | new | abstract (| virtual | public)]
    # NOTE: abstract for interfaces, abstract class's    
    def perform():void
      i = int[@foo.length]  # var i = new int[this.foo.length];
      z = :int[@foo.length] # int[] z = new int[this.foo.length];
      c = 0
      
      @foo.each do |x:int|
        puts("%d",x)
        i[c] = x 
        c += 1 
      end
      
      d(i) do |q,f|
        z[f] = q
      end
      
      # var i = new int[this.foo.length];
      # int[] z = new int[this.foo.length];
      # var c = 0;
      # public virtual void perform() {
      #   foreach (x in this.foo) {
      #     stdout.printf("%d"+"\n", x);
      #     i[c] = x;
      #   }
      #  
      #   d((q,f) => {
      #     z[f] = q;
      #   });
      # }
    end
  end
end

```
