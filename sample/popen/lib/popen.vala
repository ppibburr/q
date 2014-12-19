
public class POpen : Object {

  public class Watch : Object {
        public  Pid pid {

        get;
        construct set;

      }

    public Pipe pipe;
    public bool ok = false;

    public Watch (Pid pid) {
      MatchInfo _q_local_scope_match_data;
      int _q_local_scope_process_exit_status;

      Object(pid: pid);

    }

     public delegate void exit_cb(Pid? pid, int? status);


     public  virtual Watch? at_exit(exit_cb cb) {
      MatchInfo _q_local_scope_match_data;
      int _q_local_scope_process_exit_status;

      if (this.ok != true) {
        GLib.Idle.add(() => {
          cb(null, null);
          return ((false));

        });
        return (this);

      };
      ChildWatch.add(this.pid, (_pid, status) => {
        cb(_pid, Process.exit_status(status));
        Process.close_pid(_pid);

      });
      return (this);

    }

  }













  public class Pipe : Object {
        public  Pid pid {

        get;
        construct set;

      }

        public  int stdin {

        get;
        construct set;

      }

        public  int stdout {

        get;
        construct set;

      }

        public  int stderr {

        get;
        construct set;

      }

    public FileStream? io_in;
    public  IOChannel io_err;
    public  IOChannel io_out;

    public Pipe (Pid pid, int stdin, int stdout, int stderr) {
      MatchInfo _q_local_scope_match_data;
      int _q_local_scope_process_exit_status;

      Object(pid: pid, stdin: stdin, stdout: stdout, stderr: stderr);

    }

        construct {
      MatchInfo _q_local_scope_match_data;
      int _q_local_scope_process_exit_status;

      this.io_in = FileStream.fdopen(stdin, "w");
      this.io_err = new IOChannel.unix_new(this.stderr);
      this.io_out = new IOChannel.unix_new(this.stdout);

    }


     public  virtual void puts(string str) {
      MatchInfo _q_local_scope_match_data;
      int _q_local_scope_process_exit_status;

      this.io_in.puts(str);
      this.io_in.flush();

    }

     public signal void on_read(string str);


     public  virtual void read() {
      MatchInfo _q_local_scope_match_data;
      int _q_local_scope_process_exit_status;

      this.io_out.add_watch(GLib.IOCondition.IN | GLib.IOCondition.HUP, (channel, condition) => {
        if (condition == GLib.IOCondition.HUP) {
          return (false);

        };
        try {
        string line;
        channel.read_line(out line, null, null);
        on_read(line);
        return (true);
        } catch (IOChannelError e) {
        return (false);
        } catch (ConvertError e) {
        return (false);
        }

      });

    }

  }


   public delegate void popen_cb(Pipe obj);

  public static Watch? popen(string[] args, popen_cb cb) {
    MatchInfo _q_local_scope_match_data;
    int _q_local_scope_process_exit_status;

    int stdout;
    int stderr;
    int stdin;
    Pid pid;
    try {
    Process.spawn_async_with_pipes(null, args, Environ.get(), SpawnFlags.SEARCH_PATH | SpawnFlags.DO_NOT_REAP_CHILD, null, out pid, out stdin, out stdout, out stderr);
    var pipe = new Pipe(pid, stdin, stdout, stderr);
    cb(pipe);
    var watch = new POpen.Watch(pid);
    watch.pipe = pipe;
    watch.ok = true;
    return (watch);
    } catch(SpawnError e) {
    return (new POpen.Watch(pid));
    }

  }

}

