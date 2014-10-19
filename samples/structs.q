class N < {
  foo:int,
  bar:string
}

  def r():int;
    return(@foo)
  end;
end

def main()
  n = N() {
    foo = 9
    bar = "bar"
  }
  print("#{n.foo}\n#{n.bar}\n#{n.r()}\n")
end
