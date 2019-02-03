require "Q/edit/window"

namespace module Q
  namespace module Edit
    class Application < Gtk::Application
      @editor     = :Editor
      @window     = :Gtk::ApplicationWindow?
      @toolbar    = :Gtk::Toolbar
      @init_files = :'GLib.File[]?'

      def self.new(name: :string?)
        flags = GLib::ApplicationFlags::HANDLES_OPEN | GLib::ApplicationFlags::HANDLES_COMMAND_LINE
        _name = name != nil ? name : "org.qedit.application"
    
        Object(application_id:_name, flags:flags)      

        set_option_context_summary(get_help_summary())

        #startup.connect() do activate() end

        open.connect() do |files,hint|      
          if @window == nil
            @init_files = files
            activate()
            next
          end

          open_files(files)
        end
        
        command_line.connect() do |cl|
          aa=cl.get_arguments()
          
          (aa.length-1).times do |i|
            if i > 0
              a = aa[i]
              
              if a =~ /^\-\-(.*?)\=(.*)/
                on_opt_value(cl, $1, Shell.unquote($2))
              elsif a =~ /^\-\-(.*)/
                on_opt(cl, $1)
              else
                puts "FILE: #{a} -- #{Q::File.expand_path(a, cl.get_cwd())}"
                GLib::Idle.add() do editor.open_file(Q::File.expand_path(a, cl.get_cwd())); next false; end
              end
            end
          end
          
          register()
          activate()
         
          return 0
        end
      end
      
      def on_opt(cl:ApplicationCommandLine, o:string);
        if o=="session-list"
          cl.print("%s\n", Session.list(editor))
          exit(0) if nil == @window
        elsif o == "session-active"
          cl.print("%s\n", Session.list_active(editor))
          exit(0) if nil == @window
        elsif o == "session-clear"
          Session.clear(editor)
        elsif o == "session-restore"
          @window.present()
          Session.restore(editor)
        elsif o == "session-save"
          Session.save(editor)
        elsif o == "list-schemes"
          for id in Gtk::SourceStyleSchemeManager.get_default().scheme_ids
            cl.print("%s\n", id)
          end
          exit(0) if nil == @window
        elsif o == "close-all"
          editor.close_all()
        end
      end
      
      def on_opt_value(cl:ApplicationCommandLine, o:string, v:string); 
        if o=="session"
          GLib::Idle.add() do
            editor.session = Q::expand_path(v, cl.get_cwd())
            @window.present()
            next false
          end
        elsif o=="find"
          @editor.each_view() do |vw|
            i = -1
            
            for l in vw.edit_view.buffer.text.split("\n")
              i += 1
              cl.print("%s\n", "#{vw.edit_view.path_name}: line #{i}]  #{l}") if Regex.new(v).match(l)
            end
          end
        elsif o == "completion"
          editor.load_provider(Q::expand_path(v, cl.get_cwd()))
        elsif o == "scheme"
          editor.each_view() do |vw|
            vw.edit_view.buffer.style_scheme = Gtk::SourceStyleSchemeManager.get_default().get_scheme(v)
          end
        end
      end
      
      def get_help_summary()
        return "  Gtk Code Editor written in Q
  qedit [OPTION] [FILE1 [...]]     

  OPTIONS:
    --session-save                 save the session
    --session-restore              restore the session
    --session-clear                clear the session
    --session=SESSION_FILE_PATH    set session SESSION_FILE_PATH
    --session-list                 list files in session
    --session-active               list currently editing files
    
    --completion=COMPLETION_SOURCE Add SOURCE contents to autocompletion library
    
    --find=MATCH                   print locations of occurences of MATCH in open documents
    
    --help                         Show this message
    --version                      Show version info"
      end
      
      override; def activate()
        return if @window != nil
      
        @window = Q::Edit::ApplicationWindow.new(self)
        @editor = (:ApplicationWindow > window).editor
        
        window.show_all()

        open_files(@init_files) if @init_files != nil
      end

      def open_files(files: :GLib::File[])
        GLib::Idle.add() do
          for f in files
            editor.open_file(f.get_path())
          end
          next false
        end
      end
      
      def run(argv: :string[]) :int
        GLib::Idle.add() do
          exit(0) if is_remote
          next false
        end
        return super(argv)
      end
    end
  end
end
