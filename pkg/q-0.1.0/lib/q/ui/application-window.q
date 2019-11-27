require "Q/ui/application"

namespace module Q
  namespace module UI
    class ApplicationWindow < Gtk::ApplicationWindow
      @@count = 0
      override;new;property application:Application do 
        get do return :Application > (:Gtk::ApplicationWindow > self).application end; 
        set do (:Gtk::ApplicationWindow > self).application = value; end
      end

      def self.new(a:Application)
        Object(application:a)
  
        delete_event.connect() do
          @@count = @@count - 1
          application.quit() if @@count <= 0 && application.quit_on_last_window_exit
          next false
        end
      end
    end
  end
end
