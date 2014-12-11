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

def main()
  regex_example()

  # Initialize a new Quux
  q = Quux.new()
  
  # Connect to the `notify` event of the Property: bar.
  q.notify["bar"].connect() do
    print("q :bar, changed\n")
  end
  
  # Connect to the `said_hello` Signal
  q.said_hello.connect() do
    print("q said hello!\n")
  end
  
  # Call `say_hello` method of q.
  q.say_hello()
end
