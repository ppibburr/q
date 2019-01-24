`extern void exit(int exit_code);`
namespace module Q
  @@main_loop = :MainLoop?

  delegate; def main_cb(); end

  def self.main(cb: :main_cb?) :MainLoop
    if @@main_loop == nil
      @@main_loop = MainLoop.new()
      cb() if cb != nil
      @@main_loop.run()
    end

    return @@main_loop
  end

  def self.quit()
     @@main_loop.quit() if @@main_loop != nil
  end

  macro :send, '%v1_Q__send.%v2_Q__send'
  macro :invoke, '%v1_Q__invoke.%v2_Q__invoke()'
  macro :invoke1, '%v1.%v2(%v3)'
  macro :invoke2, '%v1.%v2(%v3,%v4)'
  macro :invoke3, '%v1.%v2(%v3,%v4,%v5)'
  macro :invokev, '%v1.%v2(%v3)'

  macro :timeout, 'GLib.Timeout.add(%v1_Q__timeout, '
  macro :idle,    'GLib.Idle.add('

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

  class File
    MODE_EXE = 509

    macro; def write(f, b);   GLib::FileUtils.set_contents(f, b, -1); end    
    macro; def chmod(f, m);   GLib::FileUtils.chmod(f, m);  end
    macro; def delete(f);     GLib::FileUtils.remove(f);    end
    macro; def rename(o, n);  GLib::FileUtils.rename(o, n); end
    macro; def symlink(a, b); GLib::FileUtils.symlink(a,b); end
    macro; def directory(f);  GLib::FileUtils.test(f, GLib::FileTest::IS_DIR); end
    macro; def exist(f);      GLib::FileUtils.test(f, GLib::FileTest::EXISTS); end
    macro; def executable(f); GLib::FileUtils.test(f, GLib::FileTest::IS_EXECUTABLE); end
    macro; def is_symlink(f); GLib::FileUtils.test(f, GLib::FileTest::IS_SYMLINK); end

    macro; def join()
      buff=:string[]
      `#{buff} = %argv_s`
      ret=Q::Iterable.join(buff, "/")
      return ret
    end

    macro :dir_monitor, 'new Q.File.Monitor(%v1_Q__File__monitor, ', 'Q/file/monitor.q'
    macro :dir_monitor_created, 'new Q.File.Monitor(%v1_Q__File__created).created(', 'Q/file/monitor.q'
    macro :dir_monitor_deleted, 'new Q.File.Monitor(%v1_Q__File__deleted).deleted(', 'Q/file/monitor.q'
   
    attr_reader path_name:string      
          
    enum module IOMode
      READ
      WRITE
      APPEND
      READ_WRITE
    end
    
    delegate; def open_cb(f: :Q::File); end
    
    def self.open(path: :string, mode: :IOMode?, cb: :open_cb?) :Q::File
      return Q::File.new(path, mode, cb)
    end    
    
    def self.__read(f:string)
      ss = :string?
      FileUtils.get_contents(f, :out.ss)
      return ss
    end     
    
    Q.ifdefpkg :'gio-2.0'    
      macro; def basename(f)
        `GLib.File.new_for_path(#{f}).get_basename()`
      end 
      
      attr_reader gfile: :GLib::File       
    
      def self.get_etag_for_path(path:string) :string
        return "%s".printf(`GLib.File.new_for_path(path).query_info("*",FileQueryInfoFlags.NOFOLLOW_SYMLINKS,null).get_etag()`)
      end
      
      def self.is_modified(path:string, etag: :string) :bool
        return etag != get_etag_for_path(path)
      end

      attr_reader io: :FileIOStream?
      attr_reader etag:string

      attr_reader output_stream: :OutputStream?
      attr_reader input_stream:  :InputStream?  

      def self.new(path: :string?, mode: :IOMode?, cb: :open_cb?)
        @_path_name = path
        @_gfile     = `GLib.File.new_for_path(path)` if path != nil 
        @_etag      = get_etag_for_path(path)
        
        @_input_stream  = gfile.read()                                     if mode == IOMode::READ
        @_output_stream = gfile.replace(@_etag, false, GLib::FileCreateFlags::NONE) if mode == IOMode::WRITE
        @_output_stream = gfile.append_to(GLib::FileCreateFlags::NONE)     if mode == IOMode::APPEND
        
        if mode == IOMode::READ_WRITE
          @_io             = gfile.open_readwrite()
          @_input_stream  = io.input_stream
          @_output_stream = io.output_stream
        end
        
        if cb != nil
          cb(self)
          input_stream.close() if input_stream   != nil
          output_stream.close() if output_stream != nil
        end    
        
        refresh()
      end
      
      def puts(txt:string) :ssize_t
        len = output_stream.write("#{txt}\n".data)
        refresh()
        return len
      end
      
      def monitor() :bool
        if Q::File.is_modified?(path_name, etag); modified(); return true end
        if !Q::File.exist?(path_name);  deleted(); return true  end
        return false
      end
      
      def refresh() :string
        @_etag = Q::File.get_etag_for_path(path_name)
        deleted() if !Q::File.exist?(path_name)
        return etag
      end
    Q.elsdef :'gio-2.0'
      def self.new(path: :string?, mode: :IOMode?, cb: :open_cb?)
        @_path_name = path
        cb(self) if cb != nil
      end
      
      def puts(txt:string)
        Q::File.write(path_name, "#{txt}\n")
      end    
    Q.defend :'gio-2.0'
    
      
     def read() :string
       return Q::File.__read(path_name)
     end    
    
     def preserve_write(path:string, data:string)
       exe = Q::File.executable?(path)
       Q::File.write(path, data)
       Q::File.chmod(path, MODE_EXE) if exe
     end
     
     signal; def deleted(); end
     signal; def modified(); end
  end

  macro; def read(f)
    Q::File.new(f).read()
  end

  macro; def ENV(n)
    GLib::Environment.get_variable(n)
  end

  macro; def vargv()
    `var #{a} = %qva`
    return a
  end

  macro; def type(v,t)
    v.type() == `typeof(#{t})`
  end

  class Env    
    def get(n:string) :string?
      return GLib::Environment.get_variable(n)
    end

    def contains(n:string) :bool
      return GLib::Environment.get_variable(n) != nil
    end

    def set(n:string, v: :string?)
      if v==nil
        GLib::Environment.unset_variable(n)
      else
        GLib::Environment.set_variable(n,v, true)
      end
    end

    def iterator() :Q::Env::Iterator
      return Q::Env::Iterator.new()
    end

    def to_h() :Q::Hash
      h=Hash[:string, :string].new()
      GLib::Environment.list_variables().each do |v|
        h[v] = get(v)
      end
      return h
    end

    def keys() :string[]
      return GLib::Environment.list_variables()
    end

    def to_string()
      Q::Iterable.join(keys(),", ")
    end

    class Iterator
      @id = 0
      @list = :'string[]?'

      def next() :bool
        self.list ||= GLib::Environment.list_variables()
        return true if @id < list.length
        return false
      end

      def get() :string[]
        n = list[id]
        res = GLib::Environment.get_variable(n)
        @id+=1
        a = :string?[]
        a << n
        a << res
        return a
      end
    end
  end

  class Hash < GLib::Object
    generic_types :T, :U
    `private T[] _keys;`
    `private U?[] _values;`

    def initialize()
      _keys = :T[0]
      _values = :U[0]
    end

    new;def set(k:T, v: :U?)
      i = Q::Iterable.find(_keys,k)
      if i < 0
        i=_keys.length

        @_keys   << k
        @_values << v
      end
    
      @_keys[i] = k
      @_values[i] = v
    end

    new;def get(k:T) :U?
      i = key_index(k)

      if i >= 0
        return _values[i]
      end
      return nil
    end

    def key_index(k:T) :int
      i=-1
      i = Q::Iterable.find(:'string[]'._keys,  :string << k)  if typeof(:T) == typeof(:string)
      i = Q::Iterable.find(:'int[]'._keys,     :int << k)     if typeof(:T) == typeof(:int)      
      i = Q::Iterable.find(:'double?[]'._keys, :double? << k) if typeof(:T) == typeof(:double?) 
      return i
    end

    def contains(k:T) :bool
      i = key_index(k)
      return true if i >= 0
      return false
    end

    def keys() :T[]
      a=:T[0]
      :T.in(_keys) do |k|
        a << k
      end

      return a
    end

    def has_key(k:T) :bool
      return contains(k)
    end

    def delete(k:T) :U?
      i = :int
      i = key_index(k)
      
      if i >= 0
        g = get(k)
        ka = :T[0]
        va = :'U?'[0]
        (_keys.length-1).times do |t|
          ka << _keys[t] if t!=i
          va << _values[t] if t!=i
        end
        self._keys = ka;
        self._values = va; 
        return g 
      end

      return nil
    end

    delegate; def each_cb(k:T, v: :U?); generic_types :T,:U;end
    def each_pair(cb:each_cb)
      i = 0
      _keys.each do |k|
        cb(k, _values[i])
        i+=1
      end
    end
  end
end
