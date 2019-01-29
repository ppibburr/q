require "Q/edit/edit_view"

namespace module Q
  namespace module Edit
    class Editor < Gtk::Paned
      @book      = :Gtk::Notebook
      @stack     = :Gtk::Stack
      @terminal  = :Vte::Terminal
      @providers = :Hash[:WordProvider?]
      
      def initialize()
        @book      = Gtk::Notebook.new()
        @stack     = Gtk::Stack.new()
        @terminal  = Vte::Terminal.new()
        @providers = Hash[:WordProvider?].new()
         
        book.enable_popup = true
         
        book.set_scrollable(true)
         
        nsw = Gtk::ScrolledWindow.new(nil,nil)
        nsw.add(Gtk::TextView.new())

        ssw = Gtk::ScrolledWindow.new(nil,nil)
        sm  = Gtk::SourceStyleSchemeChooserWidget.new()

        ssw.add(sm)
        
        sm.notify["style-scheme"].connect() do
          buffer.style_scheme = sm.style_scheme
        end

        tsw = Gtk::ScrolledWindow.new(nil,nil)
        tsw.add(@terminal)
        terminal.child_exited.connect() do |t|
          init_terminal()
        end
      
        stack.add_titled(nsw, "notes", "Notes")
        stack.add_titled(tsw, "terminal", "Terminal")
        stack.add_titled(ssw, "colours", "Colours")

        set_orientation(Gtk::Orientation::VERTICAL)
        
        add1(@book)
        add2(stack)

        realize.connect() do
          stack.set_visible_child(tsw)
        end

        add_view()

        set_position(550)

        init_terminal()
        
        terminal.key_press_event.connect() do |event|
          if (event.key.state == (Gdk::ModifierType::CONTROL_MASK | Gdk::ModifierType::SHIFT_MASK))
            if event.key.keyval == 86
              terminal.paste_clipboard()
              next true
            end        
          
            if event.key.keyval == 67
              terminal.copy_clipboard()
              next true
            end          
          end

          next false
        end
        
        key_press_event.connect() do |event|
          if (event.key.state == (Gdk::ModifierType::CONTROL_MASK | Gdk::ModifierType::SHIFT_MASK))          
            if event.key.keyval == 81
              save_all()
              next true
            end        
          end
          
          if (event.key.state == Gdk::ModifierType::CONTROL_MASK)
            if event.key.keyval == 111
              prompt_open()
              next true
            end
            
            if event.key.keyval == 110
              add_view()
              
              next true
            end                      
          end

          next false
        end

        book.switch_page.connect() do
          GLib::Idle.add() do
            view_changed()
            next false
          end
        end
        
        GLib::Timeout.add(800) do
          each_view() do |v|
            if nil != v.edit_view.file
              f=v.edit_view.file
              f.check() if f.modification_type == Q::FileModType::NONE
            end
          end
          
          next true
        end
      end

      
      def prompt_open()
        dlg = Gtk::FileChooserDialog.new("Save file ...", nil,
                                                   Gtk::FileChooserAction::OPEN,
		                                               Gtk::Stock::CANCEL,
		                                               Gtk::ResponseType::CANCEL,
		                                               Gtk::Stock::OPEN,
		                                               Gtk::ResponseType::ACCEPT)
		    if file != nil
          dlg.set_current_folder(Q::File.dirname(file))
        else
          dlg.set_current_folder($CWD)
        end                                           
		                                               
        dlg.set_modal(true)
        
        dlg.response.connect() do |int|
          if int == Gtk::ResponseType::ACCEPT
            puts "Open: #{dlg.get_filename()}"
            open_file(dlg.get_filename())
          end
          
          dlg.destroy()
        end
        
        dlg.show()    
      end

      def init_terminal()
        argv = :string["/bin/bash", "-i"]
        @terminal.spawn_sync(Vte::PtyFlags::DEFAULT, "./", argv, nil, 0, nil, nil)
      end

      def add_view() :EditWidget
        widget = EditWidget.new()
        
        widget.edit_view.buffer.changed.connect() do changed() end
        widget.edit_view.show_find.connect() do show_find() end
        widget.edit_view.show_goto.connect() do show_goto() end
        
        widget.edit_view.file_saved.connect() do 
          set_tab_label(widget, Q::File.basename(widget.edit_view.path_name))
          view_changed()
        end
        
        widget.edit_view.file_loaded.connect() do |f| 
          view_changed()
          set_tab_label(widget, Q::File.basename(f))
        end     

        box   = Gtk::Box.new(Gtk::Orientation::HORIZONTAL, 0)
        close = Gtk::Button.new();
        label = Gtk::Label.new("Untitled Document");
        
        close.image = Gtk::Image.new_from_icon_name("gtk-close", Gtk::IconSize::MENU)
        close.clicked.connect() do
          close_view(widget)
        end
    
        box.pack_start(label, true,true, 0)
        box.pack_start(close, false,false,0)

        box.show_all()

        book.append_page(widget, box)
        book.show_all()
        book.page = -1

        add_completions(widget)

        widget.edit_view.file_loaded.connect() do |path|
          set_tab_label(widget, Q::File.basename(path))
        end

        return widget 
      end
      
      def close_view(view:EditWidget)
        remove_completions(view)
        view.destroy()
      end

      def load_file(path:string)
        current.edit_view.load_file(path)
      end
      
      def load_provider(pth:string)
        return if providers[pth] != nil
       
        providers[pth] = WordProvider.new(Q::read(pth))
       
        each_view() do |view|
          providers[pth].attach(view.edit_view)
        end
      end
      
      def open_file(path:string)        
        view = get_view_for_path(path)  
          
        if view == nil
          view = add_view()
         
          view.edit_view.load_file(path)
          book.show_all()

        else
          set_view(view)
        end    
      end

      def add_completions(view:EditWidget)
        providers.for_each() do |pth,p|
          (:WordProvider > p).attach(view.edit_view)
        end
        
        for i in 0..(get_n_views()-1)
          if i != get_n_views()-1
            view.edit_view.get_completion().add_provider(get_nth_view(i).edit_view.autocomplete)
            get_nth_view(i).edit_view.get_completion().add_provider(view.edit_view.autocomplete)
          end
        end
      end

      def remove_completions(view:EditWidget)
        each_view() do |v|
          if view != v
            v.edit_view.get_completion().remove_provider(view.edit_view.autocomplete)
          end
        end
      end
      
      def set_font(desc:string)
        current.edit_view.set_font(desc)
      end

      def tab_for_child(c:EditWidget) :Gtk::Box
        return :Gtk::Box > book.get_tab_label(c)
      end

      def set_tab_label(c:EditWidget, s:string)
        (:Gtk::Label > tab_for_child(c).get_children().nth_data(0)).label = s
        v = :Value
        v = s
        book.child_set_property(c, 'menu-label', v)
      end

      def get_nth_view(i:int)
        return :EditWidget? > book.get_nth_page(i)
      end
      
      def get_n_views() :int
        return book.get_n_pages()
      end 
      
      delegate;def each_cb(w:EditWidget); end
      
      def each_view(cb:each_cb)
        for i in 0..(get_n_views()-1)
          cb(get_nth_view(i))
        end
      end
      
      def close_all()
        each_view() do |v|
          close_view(v)
        end
      end
      
      def save_all()
        set_view(get_nth_view(0))
      
        GLib::Timeout.add(200) do
          each_view() do |v|
            set_view(v)
            v.edit_view.save_file()
          end
          
          next false
        end
      end

      def get_view_for_path(path:string) :EditWidget?
        for i in 0..(get_n_views()-1)
          return get_nth_view(i) if get_nth_view(i).edit_view.path_name == path
        end

        return nil
      end
      
      def set_view(view:EditWidget)
        for i in 0..(get_n_views()-1)
          book.page = i if get_nth_view(i) == view
        end    
      end

      signal; def view_changed(); end
      signal; def show_find(); end
      signal; def show_goto(); end     
      
      property buffer: :Gtk::SourceBuffer do
        get do
          return current.edit_view.buffer
        end
      end

      property current: :EditWidget do
        get do return :EditWidget > book.get_nth_page(book.get_current_page()) end
      end

      property current_tab: :Gtk::Box do
        get do
          return :Gtk::Box > book.get_tab_label(current)
        end
      end

      property file: :string? do
        get do :owned; return current.edit_view.path_name end
      end
      
      `private string? @_session = "/tmp/q.session";`
      property session: :string? do
        get do return @_session end
        set do @_session = value; Session.restore(self) end
      end

      signal; def changed(); end
    end
  end
end
