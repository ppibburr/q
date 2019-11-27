require "Q/fetch"
namespace module Q
  class Resource
    attr_reader uri:string
    attr_reader path:string
    attr_reader basename:string
    
    def self.new(uri:string, path:string)
      @_path     = path
      @_basename = Q::File.basename(path)
      @_uri      = uri
      
      self.ensure()
    end
    
    def ensure()
      message("Checking for file: #{@path} : #{@basename}, as backed by URI #{@uri}")
      unless Q::File.exist?(Q::File.expand_path(@path))
        message("Retrieving resource: #{@uri} -> #{@path}")
        Q::Dir.mkdir_p(Q::File.dirname(Q::File.expand_path(@path)))
        begin
          Q::Fetch.uri(@uri, Q::File.dirname(Q::File.expand_path(@path)), @basename)
        rescue Error => e
        end
      end 
    end
    
    def is_local() :bool
      return Q::File.exist?(@path)
    end
  end
end

