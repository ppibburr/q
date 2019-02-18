Q::package(:"webkit2gtk-4.0")

def main(a: :string?[])
  Gtk.init(:ref.a)

  WebKit::WebContext.get_default().set_web_extensions_directory("./")
  v = WebKit::WebView.new()
  v.load_html("","")
  w = Gtk::Window.new()
  w.add(v)
  
  #w.show_all()
  #w.resize(800,600)
  
  GLib::Timeout.add(1000) do Gtk.main_quit(); next false end
  
  w.destroy.connect(Gtk.main_quit)
  Gtk.main()
end