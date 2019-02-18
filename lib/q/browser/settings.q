require "Q/browser/downloader"

namespace module Q
  namespace module Browser
    class Settings
      attr_reader web_settings: :WebKit::Settings
      attr_reader web_context: :WebKit::WebContext
      attr_reader downloader:Downloader
      
      @@__default = :Settings
      
      def self.new()
        @_web_context = WebKit::WebContext.new_with_website_data_manager(WebsiteDataManager.new(GLib::Environment.get_user_cache_dir()+"/#{GLib::Environment.get_prgname()}"))
        @_downloader  = Downloader.new(web_context)
        @_web_settings = WebKit::Settings.new()
      
      
        web_settings.user_agent = "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Ubuntu Chromium/70.0.3538.77 Chrome/70.0.3538.77 Safari/537.36"
      
        cf = web_context.website_data_manager.base_cache_directory+"/cookies.txt"
        web_context.get_cookie_manager().set_persistent_storage(cf, WebKit::CookiePersistentStorage::TEXT)

        downloader.add.connect() do |d| puts "Download" end
        downloader.complete.connect() do |d| puts "Download COMPLETE: #{d.get_destination()}." end
      end
      
      def self.get_default() :Settings
        @@__default ||= Settings.new()
        return @@__default
      end
    end
    
    class WebsiteDataManager < WebKit::WebsiteDataManager
      def self.new(base_cache_directory:string)
        Object(
            base_cache_directory: base_cache_directory,
            base_data_directory: base_cache_directory
        );
      end
    end
  end
end