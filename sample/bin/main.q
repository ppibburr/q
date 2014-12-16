require "../lib/foo.q"
# Paths are relative to the file
require "../lib/quux.q"

def regex_example()
  "foo = bar" =~ /([a-z]+) = ([a-z]+)/
  print($1+"\n")
  print($2+"\n")
  print("#{$~[1]}\n")
  print($~[2]+"\n\n\n")
end

# Delegates
#
# Defining
delegate del_name(x: :int) {:int}
#
# Using
# For a method accepting a delegate as a param like so...
def foo(val: :int, cb: :del_name):int
  return cb(val)
end
#
# Generics
#
# Defining
class Moof < Object
  generic_types :G, :T
  
  @t = :T
  @g = :G
  
  def set_t(t: :T)
    @t = t
  end 
  
  def get_t():T
    return @t
  end
end
#


def ed(x: :int, y: :int?, z: :int, d: :int?):void
  print("ed\n")
end

def main()
  regex_example()

  # Initialize a new Quux
  q = Quux.new()
  
  # Connect to the `notify` event of the Property: bar.
  q.notify["bar"].connect() do
    print("q :bar, changed: #{q.bar}\n")
  end
  
  # Connect to the `said_hello` Signal
  q.said_hello.connect() do
    print("q said hello!\n")
  end
  
  # Call `say_hello` method of q.
  q.say_hello()

  num = foo(5) do |val|
    return val * 5
  end 

  print("#{num}\n")#=> 25

foot = Moof[:int,:string].new()
foot.set_t("bar")
print(foot.get_t())
foot.g = 5
print("#{foot.g}\n")

  ed(5,nil,6)
end
