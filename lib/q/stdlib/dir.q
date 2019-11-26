Q.adddef Q_DIR

namespace module Q
  delegate; def read_dir_cb(f:string); end
  module Dir
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
    
    class Glob
      @_glob = :Posix::Glob
      
      property pathv: :string[] do get do :owned; return @_glob.pathv; end; end
      
      def self.new(path:string)
        @_glob = Posix.Glob()
        @_glob.glob(path,0,nil)
      end
      
      `#if Q_FILE`
      def get_files(m=3) :'Q.File[]'
        fa = :Q::File[]
        fa = `{}`
        for path in pathv
          fa << Q::File.open(path,:Q::FileIOMode > m,nil)
        end
        return fa
      end
      `#endif`
    end
    
    macro;def glob(path)
      Q::package(:"posix")
      Q::Dir::Glob.new(`%v1_Q__Dir__glob`).pathv
    end 

    macro;def globf(path)
      Q::package(:"posix")
      Q::Dir::Glob.new(`%v1_Q__Dir__globf`).get_files()
    end 
    
    macro :monitor, 'new Q.DirMonitor(%v1_Q__Dir__monitor, ', 'Q/stdlib/dir-monitor.q'
    macro :created, 'new Q.DirMonitor(%v1_Q__Dir__created).created(', 'Q/stdlib/dir-monitor.q'
    macro :deleted, 'new Q.DirMonitor(%v1_Q__Dir__deleted).deleted(', 'Q/stdlib/dir-monitor.q'     
  end
end
