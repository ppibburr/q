require "./lib/popen.q"

def main(args: :string[]):int
  loop = GLib::MainLoop.new()
  
  system "ruby -e 'p 9;exit(1)'"
  
  print("Process exited with: #{$?} #=> #{$? << 8}\n")

  POpen.popen(args[1..-1]) do |obj|
    obj.on_read.connect() do |l|
      print("#{l}")
      obj.puts("foo\n")
    end
    
    obj.read()
  end.at_exit() do |pid, status|
    if pid == nil
      print("Process failed to execute\n")
    else
      print("Process #{pid}: Exited with, #{status}\n")
    end
    sleep 3
    loop.quit()
  end
  
  loop.run()
  
  
  return 0
end
