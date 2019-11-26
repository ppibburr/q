Q::package(:"webkit2gtk-4.0")

require "Q/browser/settings"

namespace module Q
  namespace module Browser  
    class Document < WebKit::WebView
      @_s_ = :Settings
     
      property downloader:Downloader do get do return @_s_.downloader; end; end

      def self.new_with_related_view(d:Document)
        Object(user_content_manager: d.user_content_manager, settings: d.get_settings(), related_view: d) 
        @_s_ = d._s_
        bind_keys()
      end
      
      def self.new(s: :Settings?, uri: :string?)
    
        _s = Settings.get_default() 
        _s = s if s!=nil
        
        c =  _s.web_context
        ws = _s.web_settings
        
        Object(web_context:c, settings:ws)
        
        load_uri(uri) if uri != nil
        
        @_s_ = s
        
        bind_keys()
      end
      
      def bind_keys()
        key_press_event.connect() do |event|
          if ((event.key.state & Gtk.accelerator_get_default_mod_mask()) == Gdk::ModifierType::CONTROL_MASK)
            if event.key.keyval == Gdk::Key::f
              find()
              next true
            end  
            
            if event.key.keyval == Gdk::Key::minus
              self.zoom_level = self.zoom_level-0.1
              
              next true
            end  
            
            if event.key.keyval == Gdk::Key::equal
              self.zoom_level = self.zoom_level+0.1
              
              next true
            end
            
            if event.key.keyval == Gdk::Key::r
              reload()
              
              next true
            end  
            
            next false                    
          end
          next false
        end
      end
      
      def find_text(q:string)
        if get_find_controller().text == q
          get_find_controller().search_next()
        else
          get_find_controller().search(q, WebKit::FindOptions::WRAP_AROUND | WebKit::FindOptions::CASE_INSENSITIVE, -1)
        end
      end
      
      signal;def find();end
    end
  end
end
