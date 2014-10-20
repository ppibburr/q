class MainWindow < Gtk::Window

    @master = :Gdl::DockMaster
    @layout = :Gdl::DockLayout;

    def save_layout_cb()
        dialog = Gtk::Dialog.new_with_buttons("New Layout", nil,
                                              Gtk::DialogFlags::MODAL |
                                              Gtk::DialogFlags::DESTROY_WITH_PARENT,
                                              Gtk::Stock::OK, Gtk::ResponseType::OK);

        hbox = Gtk::Box.new(Gtk::Orientation::HORIZONTAL, 8);
        hbox.border_width = 8;
        
        content = dialog.get_content_area();
        content.pack_start(hbox, false, false, 0);

        label = Gtk::Label.new("Name:");
        hbox.pack_start(label, false, false, 0);

        entry = Gtk::Entry.new();
        hbox.pack_start(entry, true, true, 0);

        hbox.show_all();
        response = dialog.run();

        if response == Gtk::ResponseType::OK
            @layout.save_layout(entry.text);
        end
        
        dialog.destroy();
    end

    def button_dump_cb()
            # Dump XML tree.
            @layout.save_to_file("layout.xml");
            Process.spawn_command_line_async("cat layout.xml");
    end

    def create_style_button(box:Gtk::Box,
                                             group?:Gtk::RadioButton,
                                             style:Gdl::SwitcherStyle,
                                             style_text:string):Gtk::RadioButton
  
        button = Gtk::RadioButton.new_with_label_from_widget(group, style_text);
        button.show();
        button.active = @master.switcher_style == style;
        button.toggled.connect() do
            if button.active
                @master.switcher_style = style;
            end
        end
        box.pack_start(button, false, false, 0);
        return(button);
    end

    def create_styles_item(dock:Gdl::Dock):Gtk::Widget
        vbox = Gtk::Box.new(Gtk::Orientation::VERTICAL, 0);
        vbox.show();

        group = create_style_button(vbox, nil, Gdl::SwitcherStyle::ICON,
                                     "Only icon");
        group = create_style_button(vbox, group, Gdl::SwitcherStyle::TEXT,
                                     "Only text");
        group = create_style_button(vbox, group, Gdl::SwitcherStyle::BOTH,
                                     "Both icons and texts");
        group = create_style_button(vbox, group, Gdl::SwitcherStyle::TOOLBAR,
                                     "Desktop toolbar style");
        group = create_style_button(vbox, group, Gdl::SwitcherStyle::TABS,
                                     "Notebook tabs");
        return(vbox);
    end

    def create_item(button_title:string):Gtk::Widget
        vbox = Gtk::Box.new(Gtk::Orientation::VERTICAL, 0);
        vbox.show();

        button = Gtk::Button.new_with_label(button_title);
        button.show();
        vbox.pack_start(button, true, true, 0);

        return(vbox);
    end

    # creates a simple widget with a textbox inside
    def create_text_item():Gtk::Widget
        vbox = Gtk::Box.new(Gtk::Orientation::VERTICAL, 0);
        vbox.show();

        scroll = Gtk::ScrolledWindow.new(nil, nil);
        scroll.show();
        vbox.pack_start(scroll, true, true, 0);
        scroll.set_policy(Gtk::PolicyType::AUTOMATIC, Gtk::PolicyType::AUTOMATIC);
        scroll.shadow_type = Gtk::ShadowType::ETCHED_IN;
        text = Gtk::TextView.new();
        text.wrap_mode = Gtk::WrapMode::WORD;
        text.show();
        scroll.add(text);

        return(vbox);
    end

    def initialize()
        @destroy.connect(Gtk.main_quit);
        @title = "Docking widget test";
        set_default_size(400, 400);

        table = Gtk::Box.new(Gtk::Orientation.VERTICAL, 5);
        table.border_width = 10;
        add(table);

        # create the dock
        dock = Gdl::Dock.new();
        @master = dock.master;

        # ... and the layout manager
        @layout = Gdl::DockLayout.new(dock);

        # create the dockbar
        dockbar = Gdl::DockBar.new(dock);
        dockbar.set_style(Gdl::DockBarStyle::TEXT);

        box = Gtk::Box.new(Gtk::Orientation::HORIZONTAL, 5);
        table.pack_start(box, true, true, 0);

        box.pack_start(dockbar, false, false, 0);
        box.pack_end(dock, true, true, 0);

        # create the dock items
        item1 = Gdl::DockItem.new("item1", "Item #1", Gdl::DockItemBehavior::LOCKED);
        item1.add(create_text_item());
        dock.add_item(item1, Gdl::DockPlacement::TOP);
        item1.show();

        item2 = Gdl::DockItem.new_with_stock("item2",
                         "Item #2: Select the switcher style for notebooks",
                         Gtk::Stock::EXECUTE, Gdl::DockItemBehavior::NORMAL);
        item2.resize = false;
        item2.add(create_styles_item(dock));
        dock.add_item(item2, Gdl::DockPlacement.RIGHT);
        item2.show();

        item3 = Gdl::DockItem.new_with_stock("item3",
                         "Item #3 has accented characters (áéíóúñ)",
                         Gtk::Stock::CONVERT,
                         Gdl::DockItemBehavior::NORMAL | Gdl::DockItemBehavior::CANT_CLOSE);
        item3.add(create_item("Button 3"));
        dock.add_item(item3, Gdl::DockPlacement::BOTTOM);
        item3.show();

        items = :Gdl::DockItem[4];
        items[0]=Gdl::DockItem.new_with_stock("Item #4", "Item #4",
                                            Gtk::Stock::JUSTIFY_FILL,
                                            Gdl::DockItemBehavior::NORMAL |
                                            Gdl::DockItemBehavior::CANT_ICONIFY);
        items[0].add(create_text_item());
        items[0].show();
        dock.add_item(items[0], Gdl::DockPlacement::BOTTOM);
        for i in 1..3
            name = "Item ##{i + 4}"
            items[i] = Gdl::DockItem.new_with_stock(name, name, Gtk::Stock::NEW,
                                                Gdl::DockItemBehavior::NORMAL);
            items[i].add(create_text_item());
            items[i].show();

            items[0].dock(items[i], Gdl::DockPlacement::CENTER, 0);
        end

        # tests: manually dock and move around some of the items
        item3.dock_to(item1, Gdl::DockPlacement::TOP, -1);

        item2.dock_to(item3, Gdl::DockPlacement::RIGHT, -1);

        item2.dock_to(item3, Gdl::DockPlacement::LEFT, -1);

        item2.dock_to(nil, Gdl::DockPlacement::FLOATING, -1);

        box = Gtk::Box.new(Gtk::Orientation::HORIZONTAL, 5);
        table.pack_end(box, false, false, 0);

        button = Gtk::Button.new_from_stock(Gtk::Stock::SAVE);
        button.clicked.connect(self.save_layout_cb);
        box.pack_end(button, false, true, 0);

        button = Gtk::Button.new_with_label("Dump XML");
        button.clicked.connect(self.button_dump_cb);
        box.pack_end(button, false, true, 0);

        Gdl::DockPlaceholder.new("ph1", dock, Gdl::DockPlacement::TOP, false);
        Gdl::DockPlaceholder.new("ph2", dock, Gdl::DockPlacement::BOTTOM, false);
        Gdl::DockPlaceholder.new("ph3", dock, Gdl::DockPlacement::LEFT, false);
        Gdl::DockPlaceholder.new("ph4", dock, Gdl::DockPlacement::RIGHT, false);
    end
end

def main(args:string[])
    Gtk.init(args.ref!);

    win = MainWindow.new();
    win.show_all();

    Gtk.main();
end
