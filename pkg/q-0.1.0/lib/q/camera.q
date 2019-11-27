require "Q/cheese/cheese-gtk"

namespace module Q  
  class Camera < Object
    enum module SaveType
      PHOTO; VIDEO
    end
  
    @_widget = :CheeseGtk::CameraWidget
    property widget: :CheeseGtk::CameraWidget do
      get do
        return @_widget
      end
    end

    @_camera = :Cheese::Camera
    property camera: :Cheese::Camera do
      get do
        return @_widget.camera
      end
    end    

    @_playing = false
    property playing:bool do
      get do
        return @_playing
      end

      set do
        @camera.play() if value
        @camera.stop() if !value
        @_playing = :bool.value
      end
    end

    def initialize()
      @_widget = CheeseGtk::CameraWidget.new()
      
      @_widget.camera_ready.connect() do ready() end
      @_widget.camera.video_saved.connect() do saved(SaveType::VIDEO) end
      @_widget.camera.photo_saved.connect() do saved(SaveType::PHOTO) end
    end

    @recording = false
    def record(loc:string)
      @recording = true
      @camera.start_video_recording(loc)
    end

    def capture(loc:string)
      @camera.take_photo(loc)
    end

    def stop()
      @camera.stop_video_recording()
      @recording = false
    end

    signal; def ready(); end
    signal; def saved(type:SaveType); end
  end
end
