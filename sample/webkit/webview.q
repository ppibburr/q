Q::package(:"webkit2gtk-4.0")

def main(a: :string?[])
  Gtk.init(:ref.a)

  u = a[1]
  u = "http://google.com" if a[1] == nil

  v = WebKit::WebView.new()
  v.load_uri(u)
  v.load_changed.connect() do |e|
    if e == WebKit::LoadEvent::COMMITTED
      v.run_javascript('plugin_init();', nil)
    end
  end  
  w = Gtk::Window.new()
  w.add(v)
  
  w.show_all()
  w.resize(800,600)
  
  w.destroy.connect(Gtk.main_quit)
  Gtk.main()
end
