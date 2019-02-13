require "Q/edit/editor"
require "Q/qui"

namespace module Q
  namespace module Edit
    class ApplicationWindow < Gtk::ApplicationWindow
      @toolbar     = :Gtk::Toolbar
      @editor      = :Editor
      @find_widget = :Gtk::SearchEntry
      @line        = :Gtk::SpinButton
      
      def self.new(app: :Gtk::Application)
        Object(application:app)

        icontheme = Gtk::IconTheme.get_default()
        @icon = icontheme.load_icon(Gtk::STOCK_EDIT, 24, 0)

        @editor = Editor.new()

        create_toolbar()

        box = Gtk::Box.new(Gtk::Orientation::VERTICAL, 0)
        box.pack_start(toolbar, false,false,0)
        box.pack_start(editor, true, true, 0)

        connect_events()

        self.title = "QEdit - New Document"
        
        resize(900, 650)  
        add(box)
      end

      def create_toolbar()
        @toolbar     = Gtk::Toolbar.new()
        
        toolbar.get_style_context().add_class(Gtk.STYLE_CLASS_PRIMARY_TOOLBAR);

		    new_button = QUI::ToolButton.new_from_stock(QUI::Stock::NEW);
		    toolbar.add(new_button);
        new_button.clicked.connect() do
          editor.add_view()
        end

        open_button = QUI::ToolButton.new_from_stock(QUI::Stock::OPEN);
		    toolbar.add(open_button)
		    open_button.clicked.connect() do
		      editor.prompt_open()
		    end

        save_button = QUI::ToolButton.new_from_stock(QUI::Stock::SAVE);
		    toolbar.add(save_button)
        save_button.clicked.connect() do
          editor.current.edit_view.save_file()
        end

        save_as_button = QUI::ToolButton.new_from_stock(QUI::Stock::SAVE_AS);
		    toolbar.add(save_as_button)
        save_as_button.clicked.connect() do
          editor.current.edit_view.prompt_save()
        end

        toolbar.add(Gtk::SeparatorToolItem.new())
        
        config_button = QUI::ToolButton.new_from_stock(QUI::Stock::PREFERENCES);
		    toolbar.add(config_button)

        notes_button = QUI::ToolButton.new_from_stock(QUI::Stock::INFO);
		    toolbar.add(notes_button)

        terminal_button = QUI::ToolButton.new_from_stock(QUI::Stock::EXECUTE);
		    toolbar.add(terminal_button)      

        l = "terminal"
        p = 650

        notes_button.clicked.connect() do
          if editor.stack.get_visible_child_name() == "notes"
            editor.stack.set_visible_child_name(l)
            editor.position = p
            next
          end

          p = editor.position
          l = editor.stack.get_visible_child_name()
          editor.stack.set_visible_child_name("notes")
          editor.position = 200
          next
        end
        
        config_button.clicked.connect() do
          if editor.stack.get_visible_child_name() == "colours"
            editor.stack.set_visible_child_name(l)
            editor.position = p
            next
          end

          p = editor.position
          l = editor.stack.get_visible_child_name()
          editor.stack.set_visible_child_name("colours")
          editor.position = 200
          next
        end

        terminal_button.clicked.connect() do
          if editor.stack.get_visible_child_name() == "terminal"
            next
          end

          l = editor.stack.get_visible_child_name()
          editor.stack.set_visible_child_name("terminal")
          editor.position = p
          next
        end
        
        toolbar.add(Gtk::SeparatorToolItem.new())

        ti           = Gtk::ToolItem.new()
        @find_widget = Gtk::SearchEntry.new()
        ti.add(find_widget)
        toolbar.add(ti)

        toolbar.add(Gtk::SeparatorToolItem.new())

        ti = Gtk::ToolItem.new()
        @line = Gtk::SpinButton.new(nil, 1.0, 0)
        @line.adjustment.lower = 0
        @line.adjustment.upper = 100000
        @line.adjustment.step_increment  = 1.0
        ti.add(@line)
        toolbar.add(ti)

        toolbar.add(Gtk::SeparatorToolItem.new())
        
        sep = Gtk::SeparatorToolItem.new();
        sep.draw = false;
        toolbar.add(sep);
        toolbar.child_set(sep, "expand", true);
        
        toolbar.add(Gtk::SeparatorToolItem.new())      
        
        quit_button = QUI::ToolButton.new_from_stock(QUI::Stock::QUIT);
		    toolbar.add(quit_button)
		    
		    quit_button.clicked.connect() do
		      application.quit()
		    end
      end

      def connect_events()
        editor.view_changed.connect() do
          path = editor.file
          self.title = "QEdit - #{path != nil ? path : ""}"
        end

        delete_event.connect() do
          application.quit()
          next false
        end

        editor.show_find.connect() do
          @find_widget.grab_focus()
        end

        editor.show_goto.connect() do
          @line.grab_focus()
        end

        @line.value_changed.connect() do
          editor.current.edit_view.go_to(:int > @line.value-1)
        end

        @find_widget.activate.connect() do
          editor.current.edit_view.find(@find_widget.text)
        end   
        
        key_press_event.connect() do |event|
          if (event.key.state == Gdk::ModifierType::CONTROL_MASK)
            if event.key.keyval == Gdk::Key::q
              application.quit()
              next true
            end
          end
          
          next false
        end 
      end
    end  
  end
end
