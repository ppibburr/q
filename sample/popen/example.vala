
 public  int main(string[] args) {
  int _q_local_scope_process_exit_status = null;

  var loop = new GLib.MainLoop();
  Process.spawn_command_line_sync("ruby -e 'p 9;exit(1)'", null, null, out _q_local_scope_process_exit_status);
  print(@"Process exited with: $(Process.exit_status(_q_local_scope_process_exit_status)) #=> $(Process.exit_status(_q_local_scope_process_exit_status) << 8)\n");
  POpen.popen(args[1:-1], (obj) => {
  obj.on_read.connect((l) => {
    print(@"$(l)");
    obj.puts("foo\n");

  });
  obj.read();

}).at_exit((pid, status) => {
    if (pid == null) {
      print("Process failed to execute\n");

    }
    else {
      print(@"Process $(pid): Exited with, $(status)\n");

    };
    Thread.usleep((ulong)(3 * 1000 * 1000));
    loop.quit();

  });
  loop.run();
  return (0);

}
