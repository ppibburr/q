require "Q/camera"

class Main < Object
  @win = :'Gtk.Window'
  @camera = :'Q.Camera'
  
  def initialize()
    @win    = Gtk::Window.new()
    v       = Gtk::VBox.new(false,0)
    snap    = Gtk::Button.new_from_icon_name("gtk-save")
    @camera = Q::Camera.new()
    h_scale = Gtk::Scale.new_with_range(Gtk::Orientation::HORIZONTAL, 1.0, 10.0, 0.1)

    v.pack_start(h_scale, false,false,1)
    v.pack_start(camera, true,true, 1)     
    v.pack_start(snap, false,false,1)
    
    @win.add(v)
    
    @win.resize(400,400)  
    @win.show_all()

    camera.captured.connect() do
      puts "OK"
    end 

    snap.clicked.connect() do
      camera.capture("./test.png")
    end

    h_scale.value_changed.connect() do
      @camera.zoom = :float.h_scale.get_value()
    end
    
    @win.delete_event.connect() do Gtk.main_quit() end

    GLib::Timeout.add(1000) do
      camera.zoom = 3.0
      camera.record("./test2.mpg")
      GLib::Timeout.add(10000) do
        camera.stop()
      end
      return false
    end
  end

	def self.main(args: :string[])
		Gst.init(:ref.args); 
		Gtk.init(:ref.args);
   
    app = Main.new();

		Gtk.main();
	end
end
