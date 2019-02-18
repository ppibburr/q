namespace module Q
  namespace module UI
    class Application < Gtk::Application
      @quit_on_last_window_exit = true
            
      override;new;property active_window:ApplicationWindow do 
        get do return :ApplicationWindow > (:Gtk::Application > self).active_window end; 
      end      
      
      def self.new(n: :string?)
        flags = GLib::ApplicationFlags::HANDLES_OPEN | GLib::ApplicationFlags::HANDLES_COMMAND_LINE
        Object(application_id:n, flags:flags)
      
        self.activate.connect() do
          next if get_windows().length() > 0
         
          create_window()
        end
        
        self.command_line.connect() do |cl|
          opts = Opts.new()
          mkopts(opts,cl)
          
          a = opts.parse(cl.get_arguments())
          GLib::Idle.add() do open_files(a); next false; end
      
          register()
          activate()
      
          cl.unref()
      
          return 0
        end      
      
        mkopts.connect() do |opts, cl|
          opts.summary = ""
          
          opts.add("help", "Show this message").on.connect() do cl.print(opts.help()); exit(0) if get_windows().length() <= 0; end
        end
      end
     
      signal;def create_window();end
      signal;def open_files(a: :string[]); end
      signal;def mkopts(opts:Opts, cl:ApplicationCommandLine);end
    end
  end
end