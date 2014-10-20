async
def nap(interval:uint, priority?:int)
  z = :GLib::SourceFunc

  z = proc() do
    nap.callback();
    next(false);
  end
     
  GLib::Timeout.add(interval, owned(z), priority != nil ? priority : GLib::Priority::DEFAULT);
  yield;
end

async
def do_stuff()
  yield nap(1000, nil);
end

def main(args:string[]):int
  loop = GLib::MainLoop.new();
  do_stuff() do |obj, async_res|
    loop.quit();
  end;
  
  loop.run();

  return(0);
end
