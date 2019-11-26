using Gtk;

class TreeViewSample < Window
  def initialize()
    @title = "TreeView Sample";
    set_default_size(250, 100);
    view = TreeView.new();
    setup_treeview(view);
    add(view);
    @destroy.connect(Gtk.main_quit);
  end

  def setup_treeview(view: :TreeView)
    # Use ListStore to hold accountname, accounttype, balance and
    # color attribute. For more info on how TreeView works take a
    # look at the GTK+ API.
     
    listmodel = Gtk::ListStore.new(4, typeof(:string), typeof(:string), typeof(:string), typeof(:string));
    view.set_model(listmodel);

    view.insert_column_with_attributes(-1, "Account Name", CellRendererText.new(), "text", 0);
    view.insert_column_with_attributes(-1, "Type", CellRendererText.new(), "text", 1);

    cell = CellRendererText.new();
    cell.set("foreground_set", true);
    view.insert_column_with_attributes(-1, "Balance", cell, "text", 2, "foreground", 3);

    iter = :TreeIter;
    listmodel.append(:out << iter);
    listmodel.set(iter, 0, "My Visacard", 1, "card", 2, "102,10", 3, "red");

    listmodel.append(:out << iter);
    listmodel.set(iter, 0, "My Mastercard", 1, "card", 2, "10,20", 3, "red");
  end

  def self.main(args: :string[]):int
    Gtk.init(:ref << args);

    sample = TreeViewSample.new();
    sample.show_all();
    
    Gtk.main();

    return 0;
  end
end
