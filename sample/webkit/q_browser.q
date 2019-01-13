Q::package(:"webkit2gtk-4.0")

using Gtk;
using WebKit;

class QBrowser < Window
  TITLE            = "Q Browser";
  HOME_URL         = "http://acid3.acidtests.org/";
  DEFAULT_PROTOCOL = "http";

  :Regex[@protocol_regex]
  :Entry[@url_bar]
  :WebView[@web_view]
  :Label[@status_bar]
  :Button[@back_button, @forward_button, @reload_button]

  def initialize()
    @title = QBrowser::TITLE;
    set_default_size(800, 600);

    create_widgets();
    connect_signals();
    
    @url_bar.grab_focus();
  end

  def create_widgets()
    toolbar = Gtk::HBox.new(false, 0);
    @back_button    = Button.new_from_stock(Stock::GO_BACK);
    @forward_button = Button.new_from_stock(Stock::GO_FORWARD);
    @reload_button  = Button.new_from_stock(Stock::REFRESH);
    
    toolbar.pack_start(@back_button, false, false, 0);
    toolbar.pack_start(@forward_button, false, false, 0);
    toolbar.pack_start(@reload_button, false, false, 0);
    
    @url_bar  = Entry.new();
    toolbar.pack_start(@url_bar, true, true, 0)
    @web_view = WebView.new();
    
    scrolled_window = ScrolledWindow.new(nil, nil);
    scrolled_window.set_policy(PolicyType::AUTOMATIC, PolicyType::AUTOMATIC);
    scrolled_window.add(@web_view);
    
    @status_bar = Label.new("Welcome");
    @status_bar.xalign = 0;
    
    vbox = VBox.new(false, 0);
    vbox.pack_start(toolbar, false, true, 0);

    vbox.add(scrolled_window);
    vbox.pack_start(@status_bar, false, true, 0);
    
    add(vbox);
  end

  def connect_signals()
    @destroy.connect(Gtk.main_quit);
    @url_bar.activate.connect(on_activate);
    
    @web_view.notify["title"].connect() do
      @title = "#{@web_view.title} - #{QBrowser::TITLE}";
    end
    
    @web_view.load_changed.connect() do |w, e|
      if e == WebKit::LoadEvent::COMMITTED
        @url_bar.text = @web_view.get_uri();
        update_buttons();
      end
    end
    
    @back_button.clicked.connect(@web_view.go_back);
    @forward_button.clicked.connect(@web_view.go_forward);
    @reload_button.clicked.connect(@web_view.reload);
  end

  def update_buttons()
    @back_button.sensitive    = @web_view.can_go_back();
    @forward_button.sensitive = @web_view.can_go_forward();
  end

  def on_activate()
    url = @url_bar.text;
    
    unless url=~/.*:\/\/.*/
      url = "#{QBrowser::DEFAULT_PROTOCOL}://#{url}";
    end
    
    @web_view.load_uri(url);
  end

  def start()
    show_all();
    
    @web_view.load_uri(QBrowser::HOME_URL);
  end

  def self.main(args: :string[])
    Gtk.init(:ref << args);

    browser = QBrowser.new();
    browser.start();

    Gtk.main();

    return 0;
  end
end
