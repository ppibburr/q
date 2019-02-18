require "Q/browser/settings"
require "Q/browser/document"

namespace module Q
  namespace module Browser
    class Session < Q::UI::Tabbed[:Document]
      def open(u = "http://google.com")
        doc = Document.new(Settings.get_default())
        doc.load_uri(Browser.omni(u))
        append(doc)
        
        doc.notify['title'].connect() do 
          get_tab(doc).label = doc.title
          get_tab(doc).label = doc.title[0..35] if doc.title.length > 35
        end
        
        self.group_name = "any"
       
        create_window.connect() do |w,x,y|
           app = :Application > GLib::Application.get_default()
           n = Window.new(app)
           app.add_window(n)
          `weak Session wk = n.book;`
          next wk
        end
      end
      
      def self.new()
        super
        
        new_tab.connect() do
          open()
        end
        
        added.connect() do |d|        
          d.create.connect() do 
            n = Document.new(Settings.get_default())
            append(n)
            return n
          end
        end
      end
    end
  end
end  