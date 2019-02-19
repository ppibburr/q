Q::package(:'gtksourceview-3.0', :'vte-2.91')
Q::flags(:'-X -Wno-deprecated-declarations', :'-X -Wno-pointer-to-int-cast')

require "Q/edit/utils.q"
require "Q/edit/settings.q"


namespace module Q
  namespace module Edit
    class EditView < Gtk::SourceView
      @buffer    = :Gtk::SourceBuffer
      @search    = :Gtk::SourceSearchContext
      @line_mark = :Gtk::TextMark
      @draw_spaces_tag = :Gtk::SourceTag
     
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
      
      property font_string:string do set do set_font(value) end;end
      
      property scheme:string do set do 
        buffer.style_scheme = Gtk::SourceStyleSchemeManager.get_default().get_scheme(value)
      end; end
      
      property set_draws_spaces:bool do get do return @draw_spaces_tag.draw_spaces end; set do 
        if value
          buffer.tag_table.remove(@draw_spaces_tag)
          @draw_spaces_tag.draw_spaces = value
          buffer.tag_table.add(@draw_spaces_tag); 
          space_drawer.enable_matrix = true
          space_drawer.set_types_for_locations(Gtk.SourceSpaceLocationFlags::ALL,
          Gtk::SourceSpaceTypeFlags::SPACE | Gtk::SourceSpaceTypeFlags::TAB)
        else
          buffer.tag_table.remove(@draw_spaces_tag)
          space_drawer.enable_matrix = false
          space_drawer.set_types_for_locations(Gtk.SourceSpaceLocationFlags::ALL,
          Gtk::SourceSpaceTypeFlags::NONE)
        end
      end;end
      
      def initialize()
        @draw_spaces_tag = Gtk::SourceTag.new("draw_spaces");
        @buffer    = :Gtk::SourceBuffer > get_buffer()
        @search    = Gtk::SourceSearchContext.new(buffer, nil)
        
        Settings.default().update.connect() do |p, v|
          set_property(p, v)
        end
        
        Settings.default().init_view(self)

        search.set_highlight(true)

        @_autocomplete = Gtk::SourceCompletionWords.new('main', nil)
        @_autocomplete.register(buffer)

        get_completion().add_provider(@_autocomplete)      

        WordProvider.q().attach(self)
        
        connect_keys()
        
        buffer.modified_changed.connect() do 
          puts "modified"
          modify()
        end
      end

      def connect_keys()
        key_press_event.connect() do |event|
          if ((event.key.state & Gtk.accelerator_get_default_mod_mask()) == (Gdk::ModifierType::CONTROL_MASK | Gdk::ModifierType::SHIFT_MASK))
            if event.key.keyval == Gdk::Key::S
              prompt_save()
              next true
            end  
           
            if event.key.keyval == Gdk::Key::R
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

          if ((event.key.state & Gtk.accelerator_get_default_mod_mask()) == Gdk::ModifierType::CONTROL_MASK)
            if event.key.keyval == Gdk::Key::s
              save_file()
              next true;
            end

            if event.key.keyval == Gdk::Key::f
              show_find()
              next true
            end

            if event.key.keyval == Gdk::Key::l
              show_goto()
              next true;
            end
          end
          
          next false
        end
      end

      def go_to(offset=0, l:int)
        iter = :Gtk::TextIter
        buffer.get_iter_at_line(:out.iter, l)
        iter.forward_chars(offset)
        scroll_to_iter(iter, 0, false, 0, 0)
        buffer.place_cursor(iter)
      end

      def get_selected(replace_new_line = true) :string
        start, e = :Gtk::TextIter
        
        buffer.get_selection_bounds(:out.start, :out.e)
        selected = buffer.get_text(start, e, true)
      
        if (replace_new_line)
          return selected.chomp().replace("\n", " ")
        end

        return selected;
      end
      
      def find(txt:string)
        if search.settings.search_text == txt
          find_next()
          return
        end
      
        start_iter, end_iter = :Gtk::TextIter

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
        start_iter, end_iter, end_iter_tmp = :Gtk::TextIter?
        
        if buffer != nil
          buffer.get_selection_bounds(:out.start_iter, :out.end_iter);
          if !perform_search(search, end_iter, :out.end_iter_tmp)
            buffer.get_start_iter(:out.start_iter);
            perform_search(search, start_iter, :out.end_iter);
          end
        end
      end
      
      def replace(q:string, w:string)
        start_iter, end_iter   = :Gtk::TextIter?
       
        buffer.get_iter_at_offset(:out.start_iter, buffer.cursor_position);
        search.settings.search_text = q
       
        if perform_search(search, start_iter, :out.end_iter)
          begin
            search.replace2(start_iter, end_iter, w, w.length)
          rescue Error => e
            critical(e.message);
          end
        end
      end
      
      def replace_all(q:string, w:string)
        begin
          search.settings.search_text = q
          search.replace_all(w, w.length)
        rescue Error => e
          critical(e.message)
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
          file.check()
          if buffer.text =~ /\n$/
          else
            buffer.text = buffer.text+"\n"
          end
			    @file.replace(buffer.text)
			    file_saved()
			    buffer.set_modified(false);
			    modify()
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
      signal; def modify(); end
    end

    class EditWidget < Gtk::VBox
      @edit_view = :EditView
      @info_bar  = :Gtk::InfoBar
      @modify_label = :Gtk::Label
      
      def initialize()
        @edit_view = EditView.new()

        edit_view.file_saved.connect() do file_saved() end
        edit_view.file_loaded.connect() do |f| 
          @info_bar.hide()
          file_loaded(f)
        end
       
        edit_view.external_modify.connect() do |f,mt| 
          @info_bar.show()
          if mt == Q::FileModType::CHANGE
            @modify_label.label = "The file had been changed on disk. What Would you like to do?"
            (:Gtk::Container > @info_bar.get_action_area()).get_children().nth_data(2).show()
          end 
          if mt == Q::FileModType::DELETE
            @modify_label.label = "The file no longer EXISTS. What Would you like to do?" 
            (:Gtk::Container > @info_bar.get_action_area()).get_children().nth_data(2).hide()
          end
          external_modify(f,mt)
        end
        
        edit_view.show_find.connect() do show_find() end
        edit_view.show_goto.connect() do show_goto() end
        edit_view.modify.connect() do
          @info_bar.hide() if !edit_view.buffer.get_modified()
          modify()
        end
                                
        @modify_label = Gtk::Label.new("")                        
        @info_bar = Gtk::InfoBar.new_with_buttons("gtk-refresh", 1, "gtk-save", 2, "gtk-close", 3)
        @info_bar.get_content_area().add(@modify_label)
        pack_start(@info_bar,false,false,0)
        
        @info_bar.response.connect() do |r|
          load_file(path_name) if r == 1
          if r == 2
            save_file()
            @info_bar.hide() 
          end
          close(true) if r == 3
        end
                                
        sw = Gtk::ScrolledWindow.new(nil,nil)                         
        pack_start(sw,true,true,0)
        sw.add(@edit_view)
        
        sw.set_policy(Gtk::PolicyType::AUTOMATIC, Gtk::PolicyType::AUTOMATIC)
        sw.set_shadow_type(Gtk::ShadowType::IN)
      end
      
      property path_name:string do
        get do :owned;return edit_view.path_name end
        set do edit_view.path_name = value end
      end
      
      property scheme:string do
        set do edit_view.scheme = value end
      end
      
      property tab_width:uint do
        get do return edit_view.tab_width end
        set do edit_view.tab_width = value end
      end
      
      property indent_width:int do
        get do return edit_view.indent_width end
        set do edit_view.indent_width = value end
      end
      
      property highlight_current_line:bool do
        get do return edit_view.highlight_current_line end
        set do edit_view.highlight_current_line = value end
      end 

      property set_draws_spaces:bool do
        get do return edit_view.set_draws_spaces end
        set do edit_view.set_draws_spaces = value end
      end 
      
      property show_line_numbers:bool do
        get do return edit_view.show_line_numbers end
        set do edit_view.show_line_numbers = value end
      end
      
      property auto_indent:bool do
        get do return edit_view.auto_indent end
        set do edit_view.auto_indent = value end
      end  
      
      property buffer: :Gtk::SourceBuffer do; get do return edit_view.buffer end; end
      
      def get_selected() :string
        return @edit_view.get_selected()
      end
      
      def save_file()
        @edit_view.save_file()
      end
      
      def load_file(f:string)
        @edit_view.load_file(f)
      end    
      
      def find(q:string)
        @edit_view.find(q)
      end  
      
      def go_to(l:int)
        @edit_view.go_to(l)
      end
      
      def replace(q:string, w:string)
        @edit_view.replace(q,q)
      end 
      
      def replace_all(q:string, w:string)
        @edit_view.replace_all(q,w)
      end      
      
      override;def show_all();
        super()
        @info_bar.hide() if !edit_view.file.check() || edit_view.file == nil
      end              
      
      signal; def show_find(); end
      signal; def show_goto(); end
      signal; def file_saved(); end
      signal; def file_loaded(file:string); end
      signal; def external_modify(f: :Q::File, mt: :Q::FileModType); end   
      signal;def modify();end  
      signal;def close(b:bool); end                                  
    end  
  end
end
 