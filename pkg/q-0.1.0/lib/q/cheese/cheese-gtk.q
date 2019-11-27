Q::package(:'cheese', :'cheese-gtk', :'clutter-gtk-1.0', :'clutter-gst-3.0')

namespace module CheeseGtk
  class CameraWidget < GtkClutter::Embed
    @camera                  = :Cheese::Camera
    @viewport_layout_manager = :Clutter::BinLayout
    
    :Clutter::Actor[@video_preview, @viewport_layout, @background_layer] 
    
    def self.new()
      clutter_builder  = Clutter::Script.new();
      viewport         = :Clutter::Stage > get_stage()        
      
      clutter_builder.load_from_data(DATA, -1);

      @video_preview           = :Clutter::Actor     > clutter_builder.get_object("video_preview")
      @viewport_layout         = :Clutter::Actor     > clutter_builder.get_object("viewport_layout")
      @background_layer        = :Clutter::Actor     > clutter_builder.get_object("background")
      @viewport_layout_manager = :Clutter::BinLayout > clutter_builder.get_object("viewport_layout_manager")
      
      video_preview.request_mode = Clutter::RequestMode::HEIGHT_FOR_WIDTH;
      
      viewport.add_child(background_layer);
      viewport_layout.set_layout_manager(viewport_layout_manager);
      viewport.add_child(viewport_layout);

      @camera = Cheese::Camera.new(video_preview, nil, 1200, 740);

      realize.connect() do
        camera.setup();
        camera.play()

        GLib::Idle.add() do
          camera_ready()
          next false
        end
      end

      viewport.allocation_changed.connect() do |actor, box, flags|
        viewport_layout.set_size(viewport.width, viewport.height);
        background_layer.set_size(viewport.width, viewport.height);
      end
    end

    signal; def camera_ready(); end
  end
end

__END__

[
{
  "id": "video_preview",
  "type": "ClutterActor",
  "child::x-align": "CLUTTER_BIN_ALIGNMENT_CENTER",
  "child::y-align": "CLUTTER_BIN_ALIGNMENT_CENTER",
  "content-gravity": "CLUTTER_CONTENT_GRAVITY_RESIZE_ASPECT",
  "x-expand": true,
  "y-expand": true,
  "min-height":75,
  "min-width":100
},
{
  "id": "background",
  "type": "ClutterActor",
  "background-color": "Black",
  "x": 0,
  "y": 0,
  "width":768,
  "height":1024
},

{
  "id": "viewport_layout",
  "type": "ClutterActor",
  "children":
  [
    'video_preview'
  ]
},

{
  "id": "viewport_layout_manager",
  "type": "ClutterBinLayout"
}
]

