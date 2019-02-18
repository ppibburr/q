require "Q/browser/window"

namespace module Q
  namespace module Browser
    class Application < Q::UI::Application
      override;new;property active_window:Window do 
        get do return :Window > (:Gtk::Application > self).active_window end; 
      end
    
      def self.new(n:string)
        super(n)      
               
        self.create_window.connect() do
          Settings.get_default().web_settings.enable_smooth_scrolling = true
          w = Window.new(self)
          add_window(w)
          w.book.open("http://google.com")
        end
        
        mkopts.connect() do |opts, cl|
          opts.summary = "Lightweight WebBrowser written in Q"
          
          opts.add("extensions-dir", "location to load extensions from", typeof(:Q::File)).on.connect() do |v|
            Settings.get_default().web_context.set_web_extensions_directory(:string > v)
          end
          
          opts.add("clobber", "clear cache and cookies").on.connect() do 
            pth = Settings.get_default().web_context.website_data_manager.base_cache_directory
            cmd = "rm -rf #{pth}/*"
            puts cmd
            system cmd
          end
          
          opts.add("user-agent", "set the ua string", typeof(:string)).on.connect() do |v|
            Settings.get_default().web_settings.user_agent = :string > v
          end
        end
        
        open_files.connect() do |fa|
          for a in fa
            active_window.book.open(a)
          end
        end
      end
    end
  end
end