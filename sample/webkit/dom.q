using Gtk;
using WebKit;

class App < Window
  def initialize()
    add(View.new())
    
    show_all()
    
    delete_event.connect() do
      Gtk.main_quit()
    end
  end
end

class View < WebView
  HTML = "
  <html>
    <body>
    </body>
  </html>
  "
  
  def initialize()
    load_html_string(HTML,"")  
  
    self.load_finished.connect() do
      get_dom_document().body.set_inner_html("Hello!") 
    end
  end
end

def main(args: :string[])
  Gtk.init(:ref << args)
  App.new()
  Gtk.main()
end
