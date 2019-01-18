require "Q/camera"

def main(argv: :string[])
  CheeseGtk.init(:ref.argv)

  w = Gtk::Window.new()
  
  w.resize(400,400)
  c=Q::Camera.new()
  w.add(c.widget)
  w.show_all()

  c.ready.connect() do
    c.capture("./test.png")
  end

  w.delete_event.connect() do
    c.stop()
    
    GLib::Idle.add() do
      Gtk.main_quit()
      next false
    end

    next false
  end

  c.saved.connect() do |t|
    puts "Camera saved: #{t}."
  end

  GLib::Timeout.add(3000) do
    c.record("./test.mpg")

    GLib::Timeout.add(6000) do
      c.stop()

      next false
    end
    
    next false
  end

  Gtk.main()
end
