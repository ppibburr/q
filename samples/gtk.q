def main(args:string[]):int
    Gtk.init(args.ref!);

    window = Gtk::Window.new();
    window.title = "First GTK+ Program";
    window.border_width = 10;
    window.window_position = Gtk::WindowPosition::CENTER;
    window.set_default_size(350, 70);
    window.destroy.connect(Gtk.main_quit);

    button = Gtk::Button.new_with_label("Click me!");

    button.clicked.connect() do
      button.label = "Thank you";
    end

    window.add(button);
    window.show_all();

    Gtk.main();
    return(0);
end
