Q::package(:"json-glib-1.0")
namespace module Q
  namespace module Edit
    class Settings < GLib::Object
      @_show_line_marks = true
      property show_line_marks:bool do 
        get do return @_show_line_marks; end; 
        
        set do v = :Value; v = value;@_show_line_marks = value; update("show-line-marks", v); end; 
      end 
      
      @_show_line_numbers = true
      property show_line_numbers:bool do 
        get do return @_show_line_numbers; end; 
        set do  v = :Value; v = value; @_show_line_numbers = value; update("show-line-numbers", v); end; 
      end       

      @_auto_indent                   = true
      property auto_indent:bool do 
        get do return @_auto_indent; end; 
        set do  v = :Value; v = value; @_auto_indent = value; update("auto-indent", v); end; 
      end    
      
      @_set_draws_spaces                   = true
      property set_draws_spaces:bool do 
        get do return @_set_draws_spaces; end; 
        set do  v = :Value; v = value; @_set_draws_spaces = value; update("set-draws-spaces", v); end; 
      end          
      
      @_highlight_current_line        = true
      property highlight_current_line:bool do 
        get do return @_highlight_current_line; end; 
        set do  v = :Value; v = value; @_highlight_current_line = value; update("highlight-current-line", v); end; 
      end
      
      @_insert_spaces_instead_of_tabs = true
      property insert_spaces_instead_of_tabs:bool do 
        get do return @_insert_spaces_instead_of_tabs; end; 
        set do  v = :Value; v = value; @_insert_spaces_instead_of_tabs = value; update("insert-spaces-instead-of-tabs", v); end; 
      end
      
      @_tab_width    = 2
      property tab_width:int do 
        get do return @_tab_width; end;
        set do v = :Value; v = value; @_tab_width = value; update("tab-width", v); end;
      end
      
      @_indent_width = 2
      property indent_width:int do 
        get do return @_indent_width; end;
        set do v = :Value; v = value; @_indent_width = value; update("indent-width", v); end;
      end
            
      @_font         = 'Monospace Regular 10'
      property font_string:string do 
        get do return @_font; end;
        set do v = :Value; v = value; @_font = value; update("font-string", v); end;
      end
     
      @_scheme         = 'classic'
      property scheme:string do 
        get do return @_scheme; end;
        set do v = :Value; v = value; @_scheme = value; update("scheme", v); end;
      end    
      
      attr_accessor terminal_background:string  
      
      def init_view(e:EditView)
        for p in (:ObjectClass.typeof(:Settings).class_ref()).list_properties()
          if p.name != "terminal-background"
          v = :Value
          if p.value_type == typeof(:string)
            v = ""
            get_property(p.name, :ref.v)
            e.set_property(p.name, v)
          elsif p.value_type == typeof(:bool)
            v = false
            get_property(p.name, :ref.v)
            e.set_property(p.name, v)
          elsif p.value_type == typeof(:int)
            v = 0
            get_property(p.name, :ref.v)
            e.set_property(p.name, v)
          end
          end
        end
      end
      
      signal;def update(p:string, v:Value); end

      def self.new()
        @terminal_background="#2E3436"
      end
      
      @@__default = :Settings
      def self.default() :Settings
        @@__default = Settings.new() if @@__default == nil
        return @@__default
      end
      
      def self.from_json(s:string) :Settings
        obj = Json.gobject_from_data(typeof(:Q::Edit::Settings), s);
        return :Edit::Settings > obj
      end
      
      def apply_from_json(s:string)
        o = Settings.from_json(s)
        for p in (:ObjectClass.typeof(:Settings).class_ref()).list_properties()
          v = :Value
          if p.value_type == typeof(:string)
            v = ""
            o.get_property(p.name, :ref.v)
            set_property(p.name, v)
          elsif p.value_type == typeof(:bool)
            v = false
            o.get_property(p.name, :ref.v)
            set_property(p.name, v)
          elsif p.value_type == typeof(:int)
            v = 0
            o.get_property(p.name, :ref.v)
            set_property(p.name, v)
          end
        end
      end
      
      def to_string() :string
        root = Json.gobject_serialize(self);

	      generator = Json::Generator.new();
	      generator.set_root(root);
	      return generator.to_data(nil);
      end
      
      def attach_opts(app: :Application, opts:Opts, cl: :ApplicationCommandLine?)
        active=false
        opts["active"].on.connect() do active = true end
        
        opts.add("toggle-line-numbers", "toggle line numbers").on.connect() do
          Settings.default().show_line_numbers = !Settings.default().show_line_numbers if !active
          app.editor.current.show_line_numbers = app.editor.current.edit_view.show_line_numbers if active
        end
        
        opts.add("show-line-numbers", "set display of line numbers", typeof(:bool)).on.connect() do |v|
          Settings.default().show_line_numbers = :bool.v if !active
          app.editor.current.show_line_numbers = :bool.v if active
        end 
        
        opts.add("toggle-spaces", "toggle draw-spaces").on.connect() do
          Settings.default().set_draws_spaces = !Settings.default().set_draws_spaces if !active
          app.editor.current.set_draws_spaces = !app.editor.current.set_draws_spaces if active
        end
        
        opts.add("draw-spaces", "draw spaces", typeof(:bool)).on.connect() do |v|
          Settings.default().set_draws_spaces = :bool.v if !active
          app.editor.current.set_draws_spaces = :bool.v if active
        end                             
        
        opts.add("highlight-current-line", "highlights the current line", typeof(:bool)).on.connect() do |v|
          Settings.default().highlight_current_line = :bool.v if !active
          app.editor.current.highlight_current_line = :bool.v if active
        end         
        
        opts.add("indent-width", "set the indent width to INTEGER chars", typeof(:int)).on.connect() do |v|
          Settings.default().indent_width = :int.v if !active
          app.editor.current.indent_width = :int.v if active
        end   
        
        opts.add("tab-width", "set the tab width to INTEGER", typeof(:int)).on.connect() do |v|
          Settings.default().tab_width = :int.v if !active
          app.editor.current.tab_width = :int.v if active
        end
        
        opts.add("font", "set the font to STRING", typeof(:string)).on.connect() do |v|
          Settings.default().font_string = :string.v
        end 
             
        opts.add("scheme", "set color scheme", typeof(:string)).on.connect() do |s|
          Settings.default().scheme = :string > s if !active
          app.editor.current.scheme = :string > s if active
        end 
        
        opts.add("terminal-background", "set terminal background color", typeof(:string)).on.connect() do |s|
          Settings.default().terminal_background = :string > s
        end          
        
        opts.add("load-settings", "Load settings from json FILE", typeof(:Q::File)).on.connect() do |v|
          Settings.default().apply_from_json(Q.read(Q.expand_path(:string > v,cl.get_cwd())))
        end 
        
        opts.add("dump-settings", "Save settings to json FILE", typeof(:Q::File)).on.connect() do |v|
          Q.write(Q.expand_path(:string > v,cl.get_cwd()), Settings.default().to_string())
        end                    
      end
    end
  end
end  
