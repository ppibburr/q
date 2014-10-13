class Foo < Object
  delegate
  def bar_cb(s:string); end
  
  def bar(argv:string[], cb:bar_cb)
    argv.each(:string) do |s|
      cb(s)
    end
  end
end

def main(argv:string[])
  foo = Foo.new()
  
  foo.bar(argv) do |s|
    print("%s\n", s)
  end
end
