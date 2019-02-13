require "Q/edit/window"
require "Q/opts.q"

namespace module Q
  namespace module Edit
    class Application < Gtk::Application
      @editor     = :Editor
      @window     = :Q::Edit::ApplicationWindow?
      @toolbar    = :Gtk::Toolbar

      def self.new(name: :string?)
        flags = GLib::ApplicationFlags::HANDLES_OPEN | GLib::ApplicationFlags::HANDLES_COMMAND_LINE
        _name = name != nil ? name : "org.qedit.application"

        Object(application_id:_name, flags:flags)

        command_line.connect() do |cl|
          parse_opts(cl)
  
          register();activate()
          
          return 0
        end
      end

      override; def activate()        
        return if @window != nil
        base.activate()

        @window = Q::Edit::ApplicationWindow.new(self)
        @editor = (:ApplicationWindow > window).editor
        
        window.show_all()
      end
      
      def parse_opts(cl: :ApplicationCommandLine)
        opts = Opts.new()
        opts.summary = "Lightweight IDE written in Q."
        opts['help'].on.connect() do cl.print("%s\n", opts.help()); exit(0) if @window == nil; end
        
        opts.add("session", "Set the session", typeof(Q::File)).on.connect() do |s|
          GLib::Idle.add() do
            @editor.session = Q::expand_path(:string > s, cl.get_cwd()) if s != nil
            @window.present()
            next false
          end
        end
      
        opts.add("session-save", "Save the session").on.connect() do |s|
          Session.save(@editor)
        end
        
        opts.add("session-clear", "Clear the session").on.connect() do |s|
          Session.clear(@editor)
        end
        
        opts.add("session-restore", "Restore the session").on.connect() do |s|
          Session.restore(@editor)
        end
        
        opts.add("session-list", "List files of the session").on.connect() do |s|
          cl.print("%s\n", Session.list(editor))
          exit(0) if nil == @window
        end  
        
        opts.add("list", "List files of the editor").on.connect() do |s|
          cl.print("%s\n", Session.list_active(editor))
          exit(0) if nil == @window
        end   
        
        opts.add("schemes", "List color schemes").on.connect() do |s|
          for id in Gtk::SourceStyleSchemeManager.get_default().scheme_ids
            cl.print("%s\n", id)

            cl.print("%s","\0")
            
          end
          exit(0) if nil == @window
        end         
        
        opts.add("search", "set search text", typeof(:string)).on.connect() do |s|
          @window.find_widget.text = :string.s
        end  
        
        opts.add("replace", "replace text", typeof(:string)).on.connect() do |s|
          @editor.current.edit_view.search.settings.search_text = @window.find_widget.text
          @editor.current.replace(@window.find_widget.text, :string > s)
        end   

        opts.add("replace-all", "replace all text", typeof(:string)).on.connect() do |s|
          @editor.current.edit_view.search.settings.search_text = @window.find_widget.text
          @editor.current.replace_all(@editor.current.edit_view.search.settings.search_text, :string > s)
        end                   
        
        opts.add("find", "Find STRING in active files (regexp)", typeof(:string)).on.connect() do |q|
          @editor.each_view() do |vw|
            i = -1
            
            for l in vw.buffer.text.split("\n")
              i += 1
              cl.print("%s\n", "#{vw.path_name}: line #{i}]  #{l}") if Regex.new(:string > q).match(l) if q!=nil
            end
          end
        end             
       
        opts.add("completion", "load completion words from FILE", typeof(Q::File)).on.connect() do |f|
          editor.load_provider(Q::expand_path(:string > f, cl.get_cwd())) if f != nil
        end
        
        opts.add("active", "defer to the active document")
        
        Settings.default().attach_opts(self, opts, cl)
        
        GLib::Idle.add() do 
          for f in opts.parse(cl.get_arguments())
            puts "FILE: #{f} -- #{Q::File.expand_path(f, cl.get_cwd())}"
            editor.open_file(Q::File.expand_path(f, cl.get_cwd()))
           end
           cl.unref()
          next false
        end      
      end
    end
  end
end
