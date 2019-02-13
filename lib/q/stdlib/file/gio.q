Q::package(:'gio-2.0')
Q.adddef Q_FILE
require "Q/stdlib/file"

namespace module Q
  class File       
    attr_reader gfile: :GLib::File       
  
    def self.get_etag_for_path(path:string) :string
      return "%s".printf(`GLib.File.new_for_path(path).query_info("*",FileQueryInfoFlags.NOFOLLOW_SYMLINKS,null).get_etag()`)
    end
    
    def self.is_modified(path:string, etag: :string) :bool
      return etag != get_etag_for_path(path)
    end

    attr_reader path_name:string  

    attr_reader io: :FileIOStream?
    attr_reader etag: :string?
    attr_reader modification_type: :Q::FileModType
    attr_reader output_stream: :OutputStream?
    attr_reader input_stream:  :InputStream?  

    def self.new(path: :string?, mode: :Q::FileIOMode?, cb: :open_cb?)
      @_path_name  = path
      @_gfile      = `GLib.File.new_for_path(path)` if path != nil 
      
      refresh()
      
      reopen(mode,cb)   
      
      refresh()
    end
    
    def reopen(mode: :Q::FileIOMode?, cb: :open_cb?)
      @_input_stream  = gfile.read()                                     if mode == Q::FileIOMode::READ
      @_output_stream = gfile.replace(@_etag, false, GLib::FileCreateFlags::NONE) if mode == Q::FileIOMode::WRITE
      @_output_stream = gfile.append_to(GLib::FileCreateFlags::NONE)     if mode == Q::FileIOMode::APPEND
      
      if mode == Q::FileIOMode::READ_WRITE
        @_io            = gfile.open_readwrite()
        @_input_stream  = io.input_stream
        @_output_stream = io.output_stream
      end
      
      if cb != nil
        cb(self)
        close()
      end     
    end
    
    def close()
      io.close() if io!=nil
      input_stream.close()  if input_stream   != nil
      output_stream.close() if output_stream != nil
    end 
    
    def puts(txt:string) :ssize_t
      len = output_stream.write("#{txt}\n".data)
      refresh()
      return len
    end
    
    def check()
      if etag!=nil and Q::File.exist?(path_name)
        if Q::File.is_modified?(path_name, etag)
          @_modification_type = Q::FileModType::CHANGE
          modified(@modification_type);
          return true
        end
        
      end

      if etag!=nil and !Q::File.exist?(path_name)
        @_modification_type = Q::FileModType::DELETE
   
        modified(@modification_type);
        deleted();
   
        return true
      end

      return false
    end
    
    def refresh()
      begin
        if Q::File.exist?(path_name)
          @_etag = Q::File.get_etag_for_path(path_name)
        else
          @_etag = nil
        end
        
      rescue IOError => e
      end
      
      @_modification_type = Q::FileModType::NONE
      return @etag
    end
  
    def replace(s:string); Q.write(path_name, s); refresh(); end      

      
    def self.open(path: :string, mode: :Q::FileIOMode?, cb: :open_cb?) :Q::File?
      if !Q::File.exist?(path)
        if mode != Q::FileIOMode::READ
          Q::File.touch(path)
        else
          return nil
        end
      end
      
      return Q::File.new(path, mode, cb)
    end     
    
    macro; def basename(f)
      `GLib.File.new_for_path(#{f}).get_basename()`    
    end    
    
    def basename(f:string) :string
      return Q::File.basename(f)
    end       
    
    def read() :string
      return Q.read(path_name)
    end     
    
    macro :dir_monitor, 'new Q.File.Monitor(%v1_Q__File__monitor, ', 'Q/file/monitor.q'
    macro :dir_monitor_created, 'new Q.File.Monitor(%v1_Q__File__created).created(', 'Q/file/monitor.q'
    macro :dir_monitor_deleted, 'new Q.File.Monitor(%v1_Q__File__deleted).deleted(', 'Q/file/monitor.q'
   
    signal; def deleted(); end
    signal; def modified(mt: :Q::FileModType); end   
    
    property mtime: :int64 do
      get do 
        return :int64.gfile.query_info("*",FileQueryInfoFlags.NOFOLLOW_SYMLINKS,null).get_attribute_uint64(FileAttribute::TIME_MODIFIED)
      end
    end
    
    property ctime: :int64 do
      get do 
        return :int64.gfile.query_info("*",FileQueryInfoFlags.NOFOLLOW_SYMLINKS,null).get_attribute_uint64(FileAttribute::TIME_CHANGED)
      end
    end
   
    property atime: :int64 do
      get do 
        return :int64.gfile.query_info("*",FileQueryInfoFlags.NOFOLLOW_SYMLINKS,null).get_attribute_uint64(FileAttribute::TIME_ACCESS)
      end
    end        
  end
end  

