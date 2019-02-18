namespace module Q
  namespace module Browser    
    class Downloader
      @_downloads = :Gee::ArrayList[:WebKit::Download]
      attr_reader context: :WebKit::WebContext
      property downloads: :WebKit::Download[] do get do :owned; return @_downloads.to_array(); end; end
      
      def self.new(c: :WebKit::WebContext)
        @_downloads = Gee::ArrayList[:WebKit::Download].new()
        @_context = c 
        c.download_started.connect() do |d| manage(d) end
      end
      
      def manage(d: :WebKit::Download)
        @_downloads.add(d)
        
        add(d)
        
        d.received_data.connect() do 
          status(d, d.estimated_progress)
        end
        
        d.finished.connect() do complete(d) end
        d.failed.connect() do fail(d) end
        d.decide_destination.connect() do |s| save_file(d, s) ; return false; end
      end
      
      def download(u:string)
        manage(self.context.download_uri(u))
      end
      
      signal;def add(d: :WebKit::Download);      end
      signal;def fail(d: :WebKit::Download);   end
      signal;def complete(d: :WebKit::Download); end
      signal;def status(d: :WebKit::Download, p:double);   end
      signal;def save_file(d: :WebKit::Download, name:string); end
    end
  end
end