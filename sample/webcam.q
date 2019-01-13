class Main < Object
	@camerabin = :'Gst.Element'
	def initialize()
		@camerabin = Gst::ElementFactory.make("camerabin", "camera");
		camerabin.set_state(Gst::State::PLAYING);
	end

	def self.main(args: :string[])
		Gtk.init(:ref << args);
		Gst.init(:ref << args);

    app = Main.new();

		Gtk.main();
	end
end
