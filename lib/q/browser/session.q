require "Q/browser/settings"
require "Q/browser/document"

namespace module Q
  namespace module Browser
    class Session < Q::UI::Tabbed[:Document]
      def open(u = "http://google.com")
        doc = Document.new(Settings.get_default())
        doc.load_uri(Browser.omni(u))
        append(doc)
        doc.show()
        
        doc.notify['title'].connect() do 
          get_tab(doc).label = doc.title
          get_tab(doc).label = doc.title[0..35] if doc.title.length > 35
        end
        
        self.group_name = "any"
       
        create_window.connect() do |w,x,y|
          app = :Application > GLib::Application.get_default()
          n = Window.new(app)
          app.add_window(n)
          wk = :Session.weak
          wk = n.book;
          next wk
        end
      end
      
      def self.new()
        super
        
        new_tab.connect() do
          open()
        end
        
        removed.connect() do |v|
          v.destroy()
        end
        
        added.connect() do |d|  
          d.notify["title"].connect() do
            get_tab(d).label = d.title
          end
          d.notify["favicon"].connect() do
            surface = :'Cairo.ImageSurface?' > d.get_favicon()
             if surface != nil
               get_tab(d).icon = Gdk.pixbuf_get_from_surface(surface,0,0,surface.get_width(),surface.get_height())
             end
          end
              
          d.create.connect() do
            return create_document(d)
          end
        end
      end
      
      signal; def create_document(d:Document) :Document?;end
    end
  end
end  
