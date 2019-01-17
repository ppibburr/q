Q::package(:'cheese', :'cheese-gtk', :'clutter-gtk-1.0', :'clutter-gst-3.0')

namespace module CheeseGtk
  class CameraWidget < GtkClutter::Embed
    @camera                  = :'Cheese.Camera'
    @video_preview           = :'Clutter.Actor' 
    @viewport_layout         = :'Clutter.Actor'   
    @viewport_layout_manager = :'Clutter.BinLayout'
    @countdown_layer         = :'Clutter.Text'   
    @background_layer        = :'Clutter.Actor' 
    @error_layer             = :'Clutter.Text'    
    @timeout_layer           = :'Clutter.Text'     
    
    def self.new()
      clutter_builder  = Clutter::Script.new();
      viewport         = :Clutter::Stage << get_stage()        
      
      clutter_builder.load_from_data(DATA, -1);

      @video_preview           = :'Clutter.Actor'     << clutter_builder.get_object("video_preview")
      @viewport_layout         = :'Clutter.Actor'     << clutter_builder.get_object("viewport_layout");
      @viewport_layout_manager = :'Clutter.BinLayout' << clutter_builder.get_object("viewport_layout_manager");
      @countdown_layer         = :'Clutter.Text'      << clutter_builder.get_object("countdown_layer");
      @background_layer        = :'Clutter.Actor'     << clutter_builder.get_object("background")
      @error_layer             = :'Clutter.Text'      << clutter_builder.get_object("error_layer");
      @timeout_layer           = :'Clutter.Text'      << clutter_builder.get_object("timeout_layer");

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
        timeout_layer.set_position(video_preview.width/3 + viewport.width/2, viewport.height-20);
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
  "id": "countdown_layer",
  "type": "ClutterText",
  "child::x-align": "CLUTTER_BIN_ALIGNMENT_CENTER",
  "child::y-align": "CLUTTER_BIN_ALIGNMENT_CENTER",
  "text": "1",
  "font-name": "Sans 150px",
  "opacity": 0,
  "color": "White"
},
{
  "id": "error_layer",
  "type": "ClutterText",
  "child::x-align": "CLUTTER_BIN_ALIGNMENT_CENTER",
  "child::y-align": "CLUTTER_BIN_ALIGNMENT_CENTER",
  "color": "White",
  "visible": false
},
{
  "id": "timeout_layer",
  "type": "ClutterText",
  "color": "White",
  "font-name": "Sans bold 15px",
  "x": 0,
  "y": 0,
  "width":100,
  "height":20,
  "visible": false
},
{
  "id": "viewport_layout",
  "type": "ClutterActor",
  "children":
  [
    'video_preview',
    'countdown_layer',
    'error_layer'
  ]
},
{
  "id": "viewport_layout_manager",
  "type": "ClutterBinLayout"
}
]

