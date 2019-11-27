
namespace module Q; namespace module UI
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
    GO_FORWARD  = "gtk-go-forward"
    GO_BACK     = "gtk-go-back"
    REFRESH     = "gtk-refresh"
  end

  class ToolButton < Gtk::ToolButton
    def self.new_from_stock(item:string)
      Object()
      self.icon_name = item
    end
  end

  class Button < Gtk::Button
    def self.new_from_stock(item:string, relief: :Gtk::ReliefStyle?)
      Object()
      self.image = Gtk::Image.new_from_icon_name(item, Gtk::IconSize::BUTTON)
      self.relief = relief if relief != nil
    end
  end
end;end
