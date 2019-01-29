Q::package(:'gtksourceview-3.0', :'vte-2.91')
Q::flags(:'-X -Wno-deprecated-declarations', :'-X -Wno-pointer-to-int-cast')

require "Q/edit/utils.q"

namespace module Q
  namespace module Edit
    class EditView < Gtk::SourceView
      @buffer    = :Gtk::SourceBuffer
      @search    = :Gtk::SourceSearchContext
      @line_mark = :Gtk::TextMark
     
      attr_reader file: :Q::File?
      attr_reader autocomplete: :Gtk::SourceCompletionWords
      
      property title:string do get do :owned; return file.basename(path_name) end; end
      
      property path_name:string do
        get do :owned; return @file.path_name end
        set do
         if @file != nil
           load_file(value)
         else
           set_file_path(value)
         end 
        end
      end
      
      def initialize()
        @buffer    = :Gtk::SourceBuffer > get_buffer()
        @search    = Gtk::SourceSearchContext.new(buffer, nil)
        @line_mark = Gtk::TextMark.new(nil, true)

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

      def set_file_path(path:string)
        @_file = Q::File.open(path, Q::FileIOMode::READ_WRITE) do |f|
          f.refresh()
        end
        
        file.modified.connect() do |mt|
          puts "FILE: "+file.path_name
          puts "EXTERNAL MOD"
          external_modify(file, mt)
        end
      end

      def load_file(path:string)          
        set_file_path(path)

		    buffer.set_modified(false);	
			  
			  @buffer.text = @file.read()
			  
			  GLib::Timeout.add(400) do
			    set_lang()
			    file_loaded(path_name)
			    
			    next false
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
        
        if @file != nil
          dlg.set_filename(path_name)
        else
          dlg.set_current_folder($CWD)
        end
         
        dlg.set_modal(true)
        
        dlg.response.connect() do |int|
          if int == Gtk::ResponseType::ACCEPT
            @path_name = dlg.get_filename()
            
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
        if nil == @file
          prompt_save()
          
          return
        else
			    buffer.set_modified(false);
          file.check()
			    @file.replace(buffer.text)
			    file_saved()

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
      signal; def external_modify(f: :Q::File, mt: :Q::FileModType); end
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
  end
end
