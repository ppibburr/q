Q::package(:'gstreamer-video-1.0', :'gdk-x11-3.0', :'gtk+-3.0')

namespace module Q
  class Camera < Gtk::DrawingArea
    @camerabin = :'Gst.Element'
    
    def initialize()
      set_double_buffered(false)

      self.realize.connect() do
        GLib::Idle.add() do
          @camerabin = Gst::ElementFactory.make("camerabin", "camera");

          @camerabin.set_state(Gst::State::PLAYING);     
          camerabin.get_bus().set_sync_handler(on_bus_callback);
          
          next false
        end
      end

      draw.connect() do |context|
        style_context = get_style_context()
        height        = get_allocated_height();
        width         = get_allocated_width();
        color         = style_context.get_color(0);

        context.rectangle(0, 0, width, height);

        Gdk.cairo_set_source_rgba(context, color);

        context.fill();

        return true
      end
    end

    def on_bus_callback(bus: :Gst::Bus, message: :Gst::Message) :Gst::BusSyncReply
      self.message(message)

      if Gst::Video.is_video_overlay_prepare_window_handle_message(message)
        xoverlay = :'Gst.Video.Overlay'.message.src
        assert(xoverlay != nil);
        xoverlay.set_window_handle(:'uint*' << (:'Gdk.X11.Window' << get_window()).get_xid())         
        return Gst::BusSyncReply::DROP;
      end

      if message.has_name("image-done")
        captured()
        return Gst::BusSyncReply::DROP;
      end

      return Gst::BusSyncReply::PASS;
    end

    signal; def message(msg: :Gst::Message); end

    signal; def captured(); end
    
    def capture(loc:string)
      @camerabin.set("location", loc);
      
      GLib.Signal.emit_by_name(@camerabin, "start-capture")
    end

    property mode:int do
       get do
         m = :int;
         @camerabin.get("mode", :out.m);
         return m;
       end
       
       set do
         @camerabin.set("mode", value);
       end
    end

    property zoom: :float? do
      get do
        z = :float
        @camerabin.get("zoom", :out.z)
        return z
      end

      set do
        if (value==nil)
          @camerabin.set('zoom', :float << 1.0)
        end

        @camerabin.set('zoom', :float.value)
      end
    end    
  end
end
