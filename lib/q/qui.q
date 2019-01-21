Q::package(:"gtk+-3.0")

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
