`#if Q_FILE`
require "Q/stdlib/file"

namespace module Q
  class File  
    attr_reader path_name:string    
     
    def self.new(path: :string?, mode: :Q::FileIOMode?, cb: :open_cb?)
      @_path_name = path
      `#if Q_FILE_INFO`
      refresh()
      `#endif`
      cb(self) if cb != nil
      `#if Q_FILE_INFO`
      refresh() if cb != nil
      `#endif`
    end
      
    def self.open(path: :string, mode: :Q::FileIOMode?, cb: :open_cb?) :'Q.File?'
      if !Q::File.exist?(path)
        if mode != Q::FileIOMode::READ
          Q::File.touch(path)
        else
          return nil
        end
      end
      
      return Q::File.new(path, mode, cb)
    end    
    
    def replace(s:string); 
      Q.write(path_name, s); 
      `#if Q_FILE_INFO`
      refresh(); 
      `#endif`
    end    
    
    def read() :string?
      return Q.read(path_name)
    end    
    
    `#if Q_FILE_INFO`
    attr_reader etag: :string?  
    attr_reader modification_type: :Q::FileModType    
    
    def refresh()
      if Q::File.exist?(path_name)
        @_etag = "#{mtime}:#{ctime}"
      else
        @_etag = nil
      end
      
      @_modification_type = Q::FileModType::NONE
    end
    
    def check() :bool
      if (@_etag != nil) and !Q::File.exist?(path_name)
        @_modification_type = Q::FileModType::DELETE
        modified(Q::FileModType::DELETE)
        deleted()
        return true

      elsif ("#{mtime}:#{ctime}" != @etag)
        @_modification_type = Q::FileModType::CHANGE 
        modified(Q::FileModType::CHANGE)
        return true
      end

      return false
    end
    
    property mtime:Time do
      get do
        return Q::File.mtime(path_name)
      end
    end
    
    property atime:Time do
      get do
        return Q::File.atime(path_name)
      end
    end
    
    property ctime:Time do
      get do
        return Q::File.ctime(path_name)
      end
    end
    `#endif`   
    
    signal; def modified(mt: :Q::FileModType); end
    signal; def deleted(); end     
    
    macro; def basename(f)
      `#{f}.split("/")[#{f}.split("/").length-1]`    
    end    
    
    def basename(f:string) :string
      return Q::File.basename(f)
    end
  end
end
`#endif`
