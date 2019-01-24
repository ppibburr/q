Q::package(:'gtksourceview-3.0', :'vte-2.91')
Q::flags(:'-X -Wno-deprecated-declarations', :'-X -Wno-pointer-to-int-cast')

require "Q"
require "Q/qui"

namespace module QEdit
  class Session
    def self.restore(editor:Editor)
      files = Q::read(editor.session).split("\n")

      editor.each_view() do |v|
        if !(`v.edit_view.path_name in files`)
          editor.close_view(v)
        end
      end
      
      files.each do |f| editor.open_file(f) end 
    end

    def self.clear(editor:Editor)
      Q::File.write(editor.session, "")
    end
    
    def self.save(editor:Editor)
      list = ""
      
      for i in 0..(editor.book.get_n_pages()-1)
        list << "\n" if i > 0
        list << editor.get_nth_view(i).edit_view.path_name
      end
      
      Q::File.write(editor.session, list)
    end
  end

  class WordProvider
    @keyword_complete = :Gtk::SourceCompletionWords
    @buffer           = :Gtk::SourceBuffer
    
    def self.new(words:string)
      @buffer = Gtk::SourceBuffer.new(nil)

      self.words = words

      @keyword_complete = Gtk::SourceCompletionWords.new('keyword', nil)
      keyword_complete.register(buffer)
    end
    
    def attach(view:EditView)
      view.get_completion().add_provider(keyword_complete)
    end

    property words:string do
      get do :owned
        return buffer.text
      end

      set do
        buffer.begin_not_undoable_action()
        buffer.set_text(value)
        buffer.end_not_undoable_action()
      end 
    end

    `private static WordProvider? _q;`
    def self.q() :WordProvider
      `_q = new WordProvider(Q_KEYWORDS)` if _q == nil
      return _q
    end
  end

  Q_KEYWORDS = "EditView EditWidget Source SourceView SourceCompletionProvider SourceBuffer SourceSearchContext signal delegate async virtual override abstract hide namespace module class enum struct for def if end __FILE__ DATA GLib Gtk Gdk File Hash Window Button Toolbar ToolButton Box DrawingArea system read open Label property attr_reader attr_writer attr_accessor each in new initialize send FileUtils chmod mkdir write WebKit WebView WebFrame Frame Pane Notebook add set get"
  #
  class EditView < Gtk::SourceView
    @buffer    = :Gtk::SourceBuffer
    @search    = :Gtk::SourceSearchContext
    @line_mark = :Gtk::TextMark
    @file      = :Gtk::SourceFile?
    @file_modified = false
    @untitled      = true

    attr_reader autocomplete: :Gtk::SourceCompletionWords
    
    property path_name:string do
      get do :owned; return @file.location.get_path() end
      set do @file.set_location(`GLib.File.new_for_path(value)`) end
    end
    
    def initialize()
      @buffer    = :Gtk::SourceBuffer > get_buffer()
      @search    = Gtk::SourceSearchContext.new(buffer, nil)
      @line_mark = Gtk::TextMark.new(nil, true)
      @file      = Gtk::SourceFile.new()

      search.set_highlight(true)

      @_autocomplete = Gtk::SourceCompletionWords.new('main', nil)
      @_autocomplete.register(buffer)

      get_completion().add_provider(@_autocomplete)      

      WordProvider.q().attach(self)

      self.show_line_numbers = true
      self.insert_spaces_instead_of_tabs = true
      self.smart_home_end = Gtk::SourceSmartHomeEndType::ALWAYS
      self.tab_width = 2
      self.indent_width = 2
      self.insert_spaces_instead_of_tabs = true
      self.show_line_marks = true
      self.auto_indent = true

      set_font('Monospace 11')

      connect_keys()
    end

    def connect_keys()
      key_press_event.connect() do |event|
        if (event.key.state == (Gdk::ModifierType::CONTROL_MASK | Gdk::ModifierType::SHIFT_MASK))
          if event.key.keyval == 83
            prompt_save()
            next true
          end  
         
          if event.key.keyval == 82
            iter = :Gtk::TextIter
      
            buffer.get_iter_at_offset(:out.iter, buffer.cursor_position)
            line = iter.get_line()
        
            load_file(@path_name)
          
            GLib::Timeout.add(600) do
              go_to(line+1)
                
              GLib::Timeout.add(200) do
                place_cursor_onscreen()
                  
                next false
              end
                 
              next false
            end  

            next true
          end
        end
        
        if (event.key.state == Gdk::ModifierType::CONTROL_MASK)
          if event.key.keyval == 115
            save_file()
            next true;
          end

          if event.key.keyval == 102
            show_find()
            next true
          end

          if event.key.keyval == 108
            show_goto()
            next true;
          end
        end
        
        next false
      end
    end

    def go_to(l:int)
      iter = :Gtk::TextIter
      buffer.get_iter_at_line(:out.iter, l)
      buffer.delete_mark(@line_mark)
      buffer.add_mark(@line_mark, iter)
      scroll_mark_onscreen(@line_mark)
    end

    def find(txt:string)
      if search.settings.search_text == txt
        find_next()
        return
      end
    
      start_iter = :Gtk::TextIter
      end_iter   = :Gtk::TextIter

      search.settings.search_text = txt
      
      buffer.get_iter_at_offset(:out.start_iter, buffer.cursor_position)

      if perform_search(search, start_iter, :out.end_iter)
      else
        buffer.get_start_iter(:out.start_iter)
        perform_search(search, start_iter, :out.end_iter)
      end

      find_next()
    end

    def find_next()
      `Gtk.TextIter? start_iter, end_iter, end_iter_tmp;`
      if buffer != nil
        buffer.get_selection_bounds(:out.start_iter, :out.end_iter);
        if !perform_search(search, end_iter, :out.end_iter_tmp)
          buffer.get_start_iter(:out.start_iter);
          perform_search(search, start_iter, :out.end_iter);
        end
      end
    end

    def perform_search(search: :Gtk::SourceSearchContext, start_iter: :Gtk::TextIter, end_iter: :'Gtk.TextIter?'.out) :bool
      contains = search.forward2(start_iter, :out.start_iter, :out.end_iter, nil);

      if (contains)
        buffer.select_range(start_iter, end_iter);
        scroll_to_iter(start_iter, 0, false, 0, 0);
      end

      return contains
    end

    def load_file(path:string)          
      @file.location = `GLib.File.new_for_path(path)`
      @untitled      = false
      
      puts "load: #{path_name}"
      
		  buffer.set_modified(false);	
			
			Gtk::SourceFileLoader.new(buffer, file).load_async.begin(GLib::Priority::DEFAULT, nil) do      
        set_lang()

        file_loaded(path)
			end
    end

    def set_font(desc:string)
      override_font(Pango::FontDescription.from_string(desc))# if args[:font]
    end
    
    def prompt_save()
      dlg = Gtk::FileChooserDialog.new("Save file ...", nil, Gtk::FileChooserAction::SAVE,
		                                             Gtk::Stock::CANCEL,
		                                             Gtk::ResponseType::CANCEL,
		                                             Gtk::Stock::SAVE,
		                                             Gtk::ResponseType::ACCEPT)

      dlg.do_overwrite_confirmation = true
      
      dlg.set_modal(true)
      
      dlg.response.connect() do |int|
        if int == Gtk::ResponseType::ACCEPT
          @path_name = dlg.get_filename()
          @untitled  = false
          
          puts "SaveAs: #{dlg.get_filename()}"
          
          set_lang()
          save_file()
          file_saved()
        end
        
        dlg.destroy()
      end
      
      dlg.show()
    end

    def save_file()
      if @untitled
        prompt_save()
        
        return
      else
        file_saver  = Gtk::SourceFileSaver.new(buffer, file);
			  
			  buffer.set_modified(false);

			  file_saver.save_async.begin(GLib::Priority::DEFAULT, nil) do
				  file_saved()
			  end;
        
        @untitled = false
        
        puts "SAVED: #{@path_name}"
      end
    end   
    
    def set_lang()
      l    = Gtk::SourceLanguageManager.new();
		  lang = l.guess_language(@path_name, nil);
		  
		  if lang != nil
			  buffer.language = lang;
			  buffer.highlight_syntax = true;
		  elsif (lang == nil) && (@path_name=~/.*?\.q/)
		    buffer.language = l.get_language("ruby")
			  buffer.highlight_syntax = true;
		  else
			  buffer.highlight_syntax = false;
		  end    
    end 

    signal; def show_find(); end
    signal; def show_goto(); end
    signal; def file_saved(); end
    signal; def file_loaded(file:string); end
    signal; def file_externally_modified(); end
  end

  class EditWidget < Gtk::ScrolledWindow
    @edit_view = :EditView
    
    def initialize()
      @edit_view = EditView.new()

      add(@edit_view)
      
      set_policy(Gtk::PolicyType::AUTOMATIC, Gtk::PolicyType::AUTOMATIC)
      set_shadow_type(Gtk::ShadowType::IN)
    end
  end

  class Editor < Gtk::Paned
    @book     = :Gtk::Notebook
    @stack    = :Gtk::Stack
    @terminal = :Vte::Terminal
    @providers = :'Q.Hash<string, WordProvider?>'
    
    def initialize()
      @book     = Gtk::Notebook.new()
      @stack    = Gtk::Stack.new()
      @terminal = Vte::Terminal.new()
      @providers = `new Q.Hash<string, WordProvider?>()` 
       
       
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
    end

    
    def prompt_open()
      dlg = Gtk::FileChooserDialog.new("Save file ...", nil,
                                                 Gtk::FileChooserAction::OPEN,
		                                             Gtk::Stock::CANCEL,
		                                             Gtk::ResponseType::CANCEL,
		                                             Gtk::Stock::OPEN,
		                                             Gtk::ResponseType::ACCEPT)
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
      if path=~/(.*?)\.qompletions/
        pth = $1
        load_provider(pth)
        return
        
      elsif path=~/session\.(.*)/
        puts "session: #{$1}"

        if $1 == "restore"
          Session.restore(self)
        elsif $1 == "save"
          Session.save(self)
        elsif $1 == "clear"
          Session.clear(self)
        elsif $1 =~ /set\.(.*)/
          @session = $1
        end

        return
      end
        
      view = get_view_for_path(path)  
        
      if view == nil
        view = add_view()
       
        load_file(path)
        book.show_all()

      else
        set_view(view)
      end    
    end

    def add_completions(view:EditWidget)
      providers.each_pair() do |pth,p|
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

  class ApplicationWindow < Gtk::ApplicationWindow
    @toolbar = :Gtk::Toolbar
    @editor  = :Editor
    @find_widget = :Gtk::SearchEntry
    @line    = :Gtk::SpinButton
    
    def self.new(app: :Gtk::Application)
      Object(application:app)

      icontheme = Gtk::IconTheme.get_default()
      self.icon = icontheme.load_icon(Gtk::STOCK_EDIT, 24, 0)

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
          if event.key.keyval == 113
            application.quit()
            next true
          end
        end
        
        next false
      end 
    end
  end
  
  class Application < Gtk::Application
    @editor     = :Editor
    @window     = :Gtk::ApplicationWindow?
    @toolbar    = :Gtk::Toolbar
    @init_files = :'GLib.File[]?'

    def self.new(name: :string?)
      flags = GLib::ApplicationFlags::HANDLES_OPEN
      _name = name != nil ? name : "org.qedit.application"
      
      Object(application_id:_name, flags:flags)      
      
      set_option_context_summary(get_help_summary())

      open.connect() do |files,hint|      
        if @window == nil
          @init_files = files
          activate()
          next
        end

        open_files(files)
      end
    end
    
    def get_help_summary()
      return "  qedit [option]|[files]|[session.<session_command>[.<args>]]|[</path/to/completion/source>.qompletions]     

SESSION_COMMANDS:
  save     save the session
  restore  restore the session
  clear    clear the session
  set      set session to path <arg>"
    end
    
    override; def activate()
      return if @window != nil

      hold()
    
      @window = QEdit::ApplicationWindow.new(self)
      @editor = (:ApplicationWindow > window).editor
      
      window.show_all()

      open_files(@init_files) if @init_files != nil
    end

    def open_files(files: :'GLib.File[]')
      for f in files
        editor.open_file(f.get_path())
      end
    end
  end
end
