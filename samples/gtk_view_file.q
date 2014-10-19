class TextFileViewer < Gtk::Window

    @text_view = :Gtk::TextView

    def initialize()
        @title = "Text File Viewer";
        @window_position = Gtk::WindowPosition::CENTER;
        set_default_size(600, 400);

        toolbar = Gtk::Toolbar.new();
        toolbar.get_style_context().add_class(Gtk::STYLE_CLASS_PRIMARY_TOOLBAR);

        open_button = Gtk::ToolButton.new_from_stock(Gtk::Stock::OPEN);
        open_button.is_important = true;
        toolbar.add(open_button);
        open_button.clicked.connect(on_open_clicked);

        @text_view = Gtk::TextView.new();
        @text_view.editable = false;
        @text_view.cursor_visible = false;

        scroll = Gtk::ScrolledWindow.new(nil, nil);
        scroll.set_policy(Gtk::PolicyType::AUTOMATIC, Gtk::PolicyType::AUTOMATIC);
        scroll.add(@text_view);

        vbox = Gtk::Box.new(Gtk::Orientation::VERTICAL, 0);
        vbox.pack_start(toolbar, false, true, 0);
        vbox.pack_start(scroll, true, true, 0);
        add(vbox);
    end

    def on_open_clicked()
        file_chooser = Gtk::FileChooserDialog.new("Open File", self,
                                      Gtk::FileChooserAction::OPEN,
                                      Gtk::Stock::CANCEL, Gtk::ResponseType::CANCEL,
                                      Gtk::Stock::OPEN, Gtk::ResponseType::ACCEPT);
        
        if file_chooser.run() == Gtk::ResponseType::ACCEPT
            open_file(file_chooser.get_filename());
        end
        
        file_chooser.destroy();
    end

    def open_file(filename:string)
            text = :string;
            FileUtils.get_contents(filename, text.out!);
            @text_view.buffer.text = text;
    end

    static
    def main (args:string[]):int
        Gtk.init(args.ref!);

        window = TextFileViewer.new();
        window.destroy.connect(Gtk.main_quit);
        window.show_all();

        Gtk.main();
        return 0;
    end
end
