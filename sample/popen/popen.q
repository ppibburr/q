# POpen
# a `popen` like implementation
class POpen < Object
  # Handles the process `at-exit` hooks
  class Watch < Object
    # The pid of the process
    property pid: :Pid do get; construct set;end
    
    # The POpen::Pipe
    @pipe = :Pipe
    
    # True if the command could even execute 
    @ok   = false
    
    def self.new(pid: :Pid)
      Object(pid:pid)
    end
    
    # called when the ChildWatch for exiting is invoked
    delegate exit_cb(pid: :Pid?, status: :int?) {:void}
    
    # Connects a ChildWatch to the process
    def at_exit(cb: :exit_cb):Watch?
      if @ok != true
        GLib::Idle.add() do
          cb(nil,nil)
          next(false)
        end
        return self
      end
     
      ChildWatch.add(@pid) do |_pid, status|
        # Triggered when the child indicated by child_pid exits
        cb(_pid, Process.exit_status(status))
        Process.close_pid(_pid);
      end 
      
      return self
    end
  end

  # Provides simple IO to the process
  class Pipe < Object
    # The process pid
    property pid: :Pid do get; construct set; end
    # stdin fd
    property stdin: :int do get; construct set; end
    # stdout fd
    property stdout: :int do get; construct set; end
    # stderr fd
    property stderr: :int do get; construct set; end            
  
    # The stream used for writes to the process
    @io_in = :FileStream?
    # for reading from stderr, stdout
    :IOChannel[@io_err, @io_out]
  
    def self.new(pid: :Pid, stdin: :int, stdout: :int, stderr: :int)
      Object(pid:pid, stdin:stdin, stdout:stdout, stderr:stderr)
    end
    
    def initialize()        
      @io_in = FileStream.fdopen(stdin,"w")
      @io_err = IOChannel.new_unix_new(@stderr)
      @io_out = IOChannel.new_unix_new(@stdout)       
    end

    # Writes a string to the process stdin
    # performs `flush` on the stream when completed
    def puts(str: :string)
      @io_in.puts(str)
      @io_in.flush()
    end
    
    # called when a line is read from the @io_out IOChannel
    signal on_read(str: :string)
    
    # Begins reading from the @io_out via IOChannel.add_watch
    # @return [bool] true only when data was read.
    def read()
      @io_out.add_watch(GLib::IOCondition::IN | GLib::IOCondition::HUP) do |channel, condition|

        if condition == GLib::IOCondition::HUP
          return false
        end
        
        `try {`
        line = :string
        channel.read_line(:out << line, nil, nil)
        on_read(line)
      
        return true
        `} catch (IOChannelError e) {`
          return false
        `} catch (ConvertError e) {`
          return false
        `}`
      end
    end
  end

  # @yieldparam obj [Pipe] the POpen::Pipe conencted to the process
  delegate popen_cb(obj: :Pipe) {:void}
  
  # Opens a process by building a command from +args+ and connects pipes
  def self.popen(args: :string[], cb: :popen_cb):Watch?
    stdout = :int
    stderr = :int
    stdin  = :int
    
    pid = :Pid    
    
    `try {`
    Process.spawn_async_with_pipes(nil,
      args,
      Environ.get(),
      SpawnFlags::SEARCH_PATH | SpawnFlags::DO_NOT_REAP_CHILD,
      nil,
      :out << pid,
      :out << stdin,
      :out << stdout,
      :out << stderr);
      
    pipe = Pipe.new(pid, stdin, stdout ,stderr)
    
    cb(pipe)
    
    watch = POpen::Watch.new(pid) 
    watch.pipe = pipe
    watch.ok = true
    
    return watch  
    
    `} catch(SpawnError e) {`
      return POpen::Watch.new(pid)
    `}`
  end
end

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
    loop.quit()
  end
  
  loop.run()
  
  
  return 0
end
