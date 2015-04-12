using Gtk

class ListSample < Window 
  @list_store = :ListStore
  @tree_view  = :TreeView

  enum module Columns
    TOGGLE
    TEXT
    N_COLUMNS
  end

  def self.new()
    @title = "List Sample";
    @destroy.connect(Gtk.main_quit);
      
    set_size_request(200, 200);

    list_store = ListStore.new(Columns::N_COLUMNS, :bool, :string);
    tree_view  = TreeView.new_with_model(list_store);
    toggle = CellRendererToggle.new();
    
    toggle.toggled.connect() do |toggle, path|
      tree_path = TreePath.new_from_string(path);
      iter = :TreeIter;
    
      list_store.get_iter(:out << iter, tree_path);
      list_store.set(iter, Columns::TOGGLE, !toggle.active);
    end;

    column = TreeViewColumn.new();
    column.pack_start(toggle, false);
    column.add_attribute(toggle, "active", Columns::TOGGLE);
    tree_view.append_column(column);

    text = CellRendererText.new();

    column = TreeViewColumn.new();
    column.pack_start(text, true);
    column.add_attribute(text, "text", Columns::TEXT);
    
    tree_view.append_column(column);

    tree_view.set_headers_visible(false);

    iter = :TreeIter;
    list_store.append(:out << iter);
    list_store.set(iter, Columns::TOGGLE, true, Columns::TEXT, "item 1");
    list_store.append(:out << iter);
    list_store.set(iter, Columns::TOGGLE, false, Columns::TEXT, "item 2");

    add(tree_view);
  end
end


def main(args: :string[])
  Gtk.init(:ref << args);
  
  sample = ListSample.new();
  sample.show_all();
  
  Gtk.main();
end
