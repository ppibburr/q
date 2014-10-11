class Person < Object
  property age, :int, 9
   
  def initialize
    notify.connect() do |s,p| print("My property: `%s' has been changed\n", p.name) end   
  end
end

def main()
  ed = Person.new()
  ed.notify["age"].connect() do |s,p| print("changed ed's property `age'\n") end 
  ed.age = 55
  print("%d\n",ed.age)
end
