require "Q"

namespace module Q
  FILE_MODE_EXE = 509
  
  enum module FileIOMode
    READ
    WRITE
    APPEND
    READ_WRITE
  end
  
  enum module FileModType
    NONE
    CHANGE
    DELETE
  end    
  
  delegate; def open_cb(f: :Q::File?); end   
  
  module File
    include Q::Macros
  
    
    macro; def chmod(f, m);   GLib::FileUtils.chmod(f, m);  end
    macro; def delete(f);     GLib::FileUtils.remove(f);    end
    macro; def rename(o, n);  GLib::FileUtils.rename(o, n); end
    macro; def symlink(a, b); GLib::FileUtils.symlink(a,b); end
    macro; def directory(f);  GLib::FileUtils.test(f, GLib::FileTest::IS_DIR); end
    macro; def exist(f);      GLib::FileUtils.test(f, GLib::FileTest::EXISTS); end
    macro; def executable(f); GLib::FileUtils.test(f, GLib::FileTest::IS_EXECUTABLE); end
    macro; def is_symlink(f); GLib::FileUtils.test(f, GLib::FileTest::IS_SYMLINK); end
    macro; def touch(f);      Q.write(f, ""); end
    macro; def dirname(f);    GLib::Path.get_dirname(f); end
    macro; def join()
      buff=:string[]
      `#{buff} = %argv_s`
      ret=Q::Iterable.join(buff, "/")
      return ret
    end    
              
    macro; def read(f)
      `string? #{ss} = null`
   
      FileUtils.get_contents(f, :out.ss) if Q::File.exist?(f)

      return ss
    end     

    macro; def write(path, data)
      exe = Q::File.executable?(path)
      GLib::FileUtils.set_contents(path,data,data.length+1)
      Q::File.chmod(path, Q::FILE_MODE_EXE) if exe
    end
    
    macro; def mtime(path)
      Time.local(Stat(`%v1_Q__File__mtime`).st_mtime)
    end

    macro; def atime(path)
      Time.local(Stat(`%v1_Q__File__atime`).st_atime)
    end
    
    macro; def ctime(path)
      Time.local(Stat(`%v1_Q__File__ctime`).st_ctime)
    end  
    
    macro; def expand_path(f)
      Q.expand_path(f)    
    end  
  end
  
  def self.read(f:string) :string?
    s = :string?
    s = Q::File.read(f)
    return s
  end
  
  def self.write(f:string, s:string)
    Q::File.write(f,s)
  end
  
  def expand_path(f:string, cwd: :string?) :string
    r = :string?
    c = cwd == nil ? GLib::Environment.get_current_dir() : cwd
    if f =~ /^\~\//
      r = GLib::Environment.get_home_dir()+"/"+f.split("~/")[1]
    elsif f =~ /^\//
      r = f
    else
      r = c+"/"+f
    end
    o = :string[0]
    i = -1
    r.split("/").each do |q|
      i = i-1 if q == ".."
      
      if q != ".."
        i += 1
        
        if o.length-1 < i
          o << q 
        else
          o[i] = q 
        end
      end
    end
    
    return string.joinv("/", o[0..i+1])
  end
end

Q.reqifdef  Q_PKG_GIO_2_0, "Q/stdlib/file/gio"
Q.reqifndef Q_PKG_GIO_2_0, "Q/stdlib/file/fileutils"


