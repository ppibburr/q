require "Q/camera"

class Main < Object
  @win = :'Gtk.Window'
  @camera = :'Q.Camera'
  
  def initialize()
    @win    = Gtk::Window.new()
    v       = Gtk::VBox.new(false,0)
    snap    = Gtk::Button.new()
    @camera = Q::Camera.new()

    v.pack_start(snap, false,false,0)
    v.pack_start(camera,true,true,0)

    @win.add(v)
    
    @win.resize(400,400)  
    @win.show_all()

    camera.captured.connect() do
      puts "OK"
    end 

    snap.clicked.connect() do
      camera.capture("./test.png")
    end
    
    @win.delete_event.connect() do Gtk.main_quit() end

    GLib::Timeout.add(1000) do
      camera.zoom = 3.0
      camera.capture("./test.png")
      puts camera.mode
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
