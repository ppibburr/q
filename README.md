q
=

Ruby like syntax for Vala programming

Proposed translation
===

```ruby
# in class bodies
#
# $<name>  = ... #=> declare class field
# @@<name> = ... #=> declare static field
# @<name>  = ... #=> declare instance field
# <name>   = ... #=> invalid

# in functions bodies:
#
# $<name>  = ... #=> set class field/property
# @@<name> = ... #=> set static field/property
# @<name>  = ... #=> set instance field/property
# <name>   = ... #=> set local
#
# $<name>   get class field/property
# @@<name>  get static field/property
# @<name>   get instance field/property
# <name>    get local

# Declaring explicit types
#
# n   = :int                 # int name;
# n   = :int[]               # int[] name;
# n   = :int[4]              # int[] name = new int[4];
# n   = :"ArrayList<string>" # ArrayList<string> name;

# Local inference
#
# scope does not have 'a'
# a = 1                     # var a = 1;
# a = int[4]                # var a = new int[4];
# a = ArrayList(string).new # var a = new ArrayList<string> ();  
# a = [1,n,z,4]             # raise: needs; a = :int[], first 
#
# if a is in local scope ...
#
# a = 1         # a = 1;
# a = [1,2,3]   # a = {1,2,3};
# ...


namespace N do
  module Foo [Object]
  end

  class N < Object
    include Foo        
            
    # static field
    @@foo = :int[4]
    
    # static property
    sattr_accessor :bar, :int


    # class field
    $quux = :int[4] 
    
    # class property
    cattr_accessor :moof, :int 

    # instance field
    @ins_fld = :int[4]

    # instance property
    attr_accessor :ins_p, :int[4]    

 
    class << self
    end
    
    def self.inherited
    end
    
    def self.new
    end
    
    def self.with_property(prop:int):constructor
    end
    
    def initialize
    end
    
    delagate
    def del(a:int[]):void
    end
    
    def d(a:int[], b:del):void
      b(a);
    end
    
    def self.baz():void
    end
       
    def perform():void
      i = int[@ins_p.length]  
      z = :int[@ins_p.length]
      c = 0
      
      @ins_p.each do |x:int|
        puts("%d",x)
        i[c] = x 
        c += 1 
      end
      
      d(i) do |q,f|
        z[f] = q
      end
    end
  end
end

```

becomes

```vala
namespace Quux {  
  interface Foo : Object {

  }    
  
  pubic class N : Object, Foo {
    private static int[] foo = new int[4]; 
    protected static int bar { get;set;}
    
    protected class int[] quux = new int[4];
    protected class int moof { get;set;}
    
    public float ins_fld = 4f;
    public int[] ins_p { get;set; default = new int[4];}
         
    delegate void public del (int[] a) { }      
    
    static public void baz() {
    
    }     
    
    public Type() {
      
    }
    
    // Q Source had empty body
    // so we GObject style construct
    public Type.with_property(int prop) {
      Object(propName: prop);  
    }    
    
    static construct {
      
    }
    
    construct {
      
    }
    
    public void d (int a, del b) {
      b(a);
    }     
        
    public virtual void perform() {    
      var   i = new int[this.ins_p.length];
      int[] z = new int[this.ins_p.length];
      var c = 0;      
    
      foreach (x in this.ins_p) {
        stdout.printf("%d"+"\n", x);
        i[c] = x;
      }
      
      d((q,f) => {
        z[f] = q;
      });
    } 
  }
}
```
