`extern void exit(int exit_code);`

Q.adddefif Q_STD, Q_HASH, Q_ENV, Q_FILE, Q_FILE_INFO, Q_MAIN

namespace module Q
  macro :send, '%v1_Q__send.%v2_Q__send'
  macro :invoke, '%v1_Q__invoke.%v2_Q__invoke()'
  macro :invoke1, '%v1.%v2(%v3)'
  macro :invoke2, '%v1.%v2(%v3,%v4)'
  macro :invoke3, '%v1.%v2(%v3,%v4,%v5)'
  macro :invokev, '%v1.%v2(%v3)'

  macro; def cc_time()
    Q::eval(:'string', 'Time::now.to_s')
  end

  delegate; def read_dir_cb(f:string); end
  module Dir
    include Q::Macros

    macro; def read(d, cb)
      dir = GLib::Dir.open(d, 0);
      files = :string[]
      `#{files} = {};`

      c = :Q::read_dir_cb
      `#{c} = #{cb}`

      name = dir.read_name()
      while name
        files << name
        c(name) if $M > 1
        name = dir.read_name()        
      end
      return files
    end

    macro; def cwd()
      GLib::Environment.get_current_dir()
    end

    macro; def mkdir(path)
      GLib::DirUtils.create(path, 755)
    end

    macro; def mkdir_p(path)
      GLib::DirUtils.create_with_parents(path, 755)
    end    
  end
  
  macro; def cwd()
    GLib::Environment.get_current_dir()
  end

  delegate; def spawn_sync_cb(status:int, o:string, e:string); end
  macro; def system(cmd, cb)
    status = :int
    stdout_ = :string
    stderr = :string
    
    GLib::Process.spawn_command_line_sync(cmd,  :out.stdout_, :out.stderr, :out.status);

    es = Process.exit_status(status);

    if $M > 1
      c = :Q::spawn_sync_cb
     `#{c} = #{cb}`
      c(es, stdout_, stderr)
    end

    return es
  end

  module Iterable
    include Q::Macros
    macro; def join(a,j)
      c = 0
      `string? #{x} = #{j}`
      s = ""

      a.each do |m|
        if (c) > 0 
          s << x
        end

        s << m.to_string()
      
        c += 1;
      end

      return s
    end

    macro; def find(a, q, m)
      o = -1
      c = 0

      a.each do |i|
        if `#{i}#{m}` == q
          o = c
          `break`
        end

        c += 1
      end

      return o
    end
  end

  module Array
    include Q::Macros
    macro; def index(q, w)
      ret = Q::Iterable.find(q, w)
      return ret
    end

    macro; def values()
      ret = `%qva`
      return ret
    end
  end

  macro; def ENV(n)
    GLib::Environment.get_variable(n)
  end

  macro; def vargv()
    `var #{a} = %qva`
    return a
  end

  macro; def type(v,t)
    `#{v} is #{t}`
  end
end

Q.reqifdef Q_HASH, "Q/stdlib/hash"
Q.reqifdef Q_ENV,  "Q/stdlib/env"

Q.reqifdef Q_FILE,  "Q/stdlib/file"
Q.reqifdef Q_MAIN, "Q/main.q"

