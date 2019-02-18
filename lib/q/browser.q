Q::package(:"webkit2gtk-4.0")
Q::package(:"gee-0.8")

require "Q/ui/tabbed"
require "Q/ui/application-window"
require "Q/opts"
require "Q/browser/application"

namespace module Q
  namespace module Browser
    HOME_URL         = "http://google.com";
    DEFAULT_PROTOCOL = "http";
  
    def self.omni(url:string)
      u = ""
      u = url
        
      unless u=~/.*:\/\/.*/
        unless u =~ /\./
          u = "google.com/search?q=#{string.joinv("+", url.split(" "))}"
        end
        u = "#{Browser::DEFAULT_PROTOCOL}://#{u}";
      end
      
      return u
    end
  end
end