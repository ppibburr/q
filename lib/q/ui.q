Q::package(:"gtk+-3.0")

namespace module Q
  namespace module UI
    class QApp < Gtk::Application
      @window = :Gtk::ApplicationWindow

      delegate;def activate_cb(app:QApp); end
      @on_activate = :activate_cb
   
      def self.new(id:string, flags: :ApplicationFlags, cb:activate_cb)
        Object(application_id:id, flags:flags)
        this.on_activate = cb
      end

      override;def activate()
        @window = Gtk::ApplicationWindow.new(self);
        self.on_activate(self)
        @window.show_all();
      end
    end

    def self.app(i:string, flags: :ApplicationFlags, cb: :QApp::activate_cb)
      app = QApp.new(i,flags, cb)
      app.run()
    end
  end

  macro :app, 'Q.UI.app(%v1_Q__app, ApplicationFlags.FLAGS_NONE, '  
end

namespace module QUI
  class Stock
    OPEN  = "gtk-open"
    CLOSE = "gtk-close"
    SAVE  = "gtk-save"
    SAVE_AS = "gtk-save-as"
    EDIT = "gtk-edit"
    FILE = "gtk-file"
    NEW  = "gtk-new"
    QUIT = "gtk-quit"
    PREFERENCES = "gtk-preferences"
    INFO        = "gtk-dialog-info"
    EXECUTE     = "gtk-execute"
  end

  class ToolButton < Gtk::ToolButton
    def self.new_from_stock(item:string)
      Object()
      self.icon_name = item
    end
  end

  class Button < Gtk::Button
    def self.new_from_stock(item:string)
      Object()
      self.image = Gtk::Image.new_from_icon_name(item, Gtk::IconSize::BUTTON)
    end
  end
end


