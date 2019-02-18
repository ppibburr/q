require "Q/browser/session"

namespace module Q
  namespace module Browser
    class Window < Q::UI::ApplicationWindow
      :Regex[@protocol_regex]
      :Gtk::Entry[@url_bar]
      :Session[@book]
      :Gtk::Label[@status_bar]
      :'Q.UI.Button'[@back_button, @forward_button, @reload_button]
      @find_bar = :Gtk::InfoBar
      
      def self.new(app:Application)
        Object(application: app)
        
        @title = "QBrowser - ";
      
        set_size_request(1000, 650);
        set_default_size(1000, 650)
        create_widgets();
        connect_signals();
        
        @url_bar.grab_focus();
        
        show_all()
        @find_bar.hide()
      end

      def create_widgets()
        toolbar = Gtk::HBox.new(false, 0);
        
        @back_button    = Q::UI::Button.new_from_stock(Q::UI::Stock::GO_BACK);
        @forward_button = Q::UI::Button.new_from_stock(Q::UI::Stock::GO_FORWARD);
        @reload_button  = Q::UI::Button.new_from_stock(Q::UI::Stock::REFRESH);
        
        toolbar.pack_start(@back_button, false, false, 0);
        toolbar.pack_start(@forward_button, false, false, 0);
        toolbar.pack_start(@reload_button, false, false, 0);
        
        @url_bar  = Gtk::Entry.new();
        toolbar.pack_start(@url_bar, true, true, 0)
        
        @book = Session.new()
        
        @status_bar = Gtk::Label.new("Welcome");
        @status_bar.xalign = 0;
        
        vbox = Gtk::VBox.new(false, 0);
        vbox.pack_start(toolbar, false, true, 0);

        @find_bar = Gtk::InfoBar.new_with_buttons("gtk-go-back", 1, "gtk-go-forward", 2, "gtk-cancel", 3,nil)
        find = Gtk::SearchEntry.new()
        find.set_hexpand(true)
        @find_bar.get_content_area().add(find)
        @find_bar.hide()
        vbox.pack_start(@find_bar,false,false,0)

        vbox.add(@book);
        vbox.pack_start(@status_bar, false, true, 0);
        
        add(vbox);
      end

      def connect_signals()
        @url_bar.activate.connect(on_activate);
        
        book.page_removed.connect() do
          destroy() if book.length == 0
        end
        
        (:Gtk::SearchEntry > @find_bar.get_content_area().get_children().nth_data(0)).activate.connect() do
          q = (:Gtk::SearchEntry > @find_bar.get_content_area().get_children().nth_data(0)).text
          book.current.find_text(q)
        end
        
        @find_bar.response.connect() do |c|
          if c == 3
            @find_bar.hide()
            book.current.get_find_controller().search_finish()
            book.current.get_find_controller().search("",0,-1)
            book.current.grab_focus()
          else
            q = (:Gtk::SearchEntry > @find_bar.get_content_area().get_children().nth_data(0)).text
            book.current.find_text(q) if book.current.get_find_controller().text != q
            book.current.find_text(q) if c == 2
            book.current.get_find_controller().search_previous() if c == 1
          end
        end
        
        book.added.connect() do |web_view|
          web_view.notify["title"].connect() do
            @title = "#{web_view.title} - #{'QBrowser'}";
          end
          
          web_view.load_changed.connect() do |w, e|
            if @book.current == web_view
              if e == WebKit::LoadEvent::COMMITTED
                @status_bar.label = web_view.get_uri()[0..35]
                @url_bar.text = web_view.get_uri();
              
                update_buttons() 
              end
            end
          end        
          
          web_view.find.connect() do
            @find_bar.show()
            e = (:Gtk::SearchEntry > @find_bar.get_content_area().get_children().nth_data(0))
            e.text=""
            e.grab_focus()
          end
        end
        
        @book.view_changed.connect(update_buttons)
        
        @back_button.clicked.connect()    do @book.current.go_back();    @book.current.grab_focus(); end
        @forward_button.clicked.connect() do @book.current.go_forward(); @book.current.grab_focus(); end
        @reload_button.clicked.connect()  do @book.current.reload();     @book.current.grab_focus(); end
      end

      def update_buttons()
        @url_bar.text             = @book.current.get_uri()
        @back_button.sensitive    = @book.current.can_go_back();
        @forward_button.sensitive = @book.current.can_go_forward();
      end

      def on_activate()
        url = Browser.omni(@url_bar.text)
        
        @book.current.load_uri(url);
        @book.current.grab_focus()
      end
    end
  end
end