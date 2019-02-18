require "Q/ui/stock-utils"
require "Q/stdlib/hash"

namespace module Q
  namespace module UI
    class Tabbed < Gtk::Notebook
      class Tab < Gtk::HBox
        attr_reader label_widget: :Gtk::Label
        attr_reader close: :'Q.UI.Button'
      
        property label:string do
          get do :owned; return @label_widget.label; end
          set do; @label_widget.label = value; end
        end
      
        def self.new()
          @_label_widget = Gtk::Label.new("")
          @_label_widget.ellipsize = Pango::EllipsizeMode::END
          @_close = Q::UI::Button.new_from_stock(Q::UI::Stock::CLOSE)
          @_close.relief = Gtk::ReliefStyle::NONE
          pack_start(@label_widget, true,true,0)
          pack_start(@close,false,false,0)
          
          show_all()
        end
      end
      
      generic_types :T
      
      @_named = :'Hash<T?>'
      
      def self.new()
        Object()
        @_named = Hash[:T?].new()
        key_press_event.connect() do |event|
          if ((event.key.state & Gtk.accelerator_get_default_mod_mask()) == Gdk::ModifierType::CONTROL_MASK)
            if event.key.keyval == Gdk::Key::n
              new_tab()
              
              next true
            end  
            
            next false                    
          end
          next false
        end
        
        switch_page.connect() do
          GLib::Idle.add() do
            view_changed()
            next false
          end
        end
      end
      
      def append(t: :T)
        tl = Tab.new()
        append_page(:Gtk::Widget > t, tl)
        (:Gtk::Widget > t).show()
        added(t)
        tl.close.clicked.connect() do 
          for i in 0..length-1
            remove_page(i) if get(i) == t
          end
        end
        set_tab_detachable(:Gtk::Widget > t, true)
        self.page = -1
        v = :Value
        v = true
        child_set_property(:Gtk::Widget > t, "tab-expand", v)
      end
      
      new;def get(i:int) :T
        return :T > get_nth_page(i)
      end
      
      new;def set(i:int, v: :T)
        insert_page(:Gtk::Widget > v,Tab.new(), i)
      end
      
      property length:int do
        get do return get_n_pages() end
      end          
            
      property view: :T do; set do
        for i in 0..(length-1)
          self.page = i if get(i) == value
        end    
      end; get do :owned; return current end; end
      
      signal;def added(v: :T); end
      signal;def new_tab();end
      signal;def view_changed();end
      
      property current: :T do
        get do :owned;return get(get_current_page()) end
      end

      property current_tab:Tab do
        get do :owned
          return :Tab > get_tab_label(:Gtk::Widget > current)
        end
      end  
      
      def get_tab(t:T) :Tab
        return :Tab > get_tab_label(:Gtk::Widget > t)
      end
      
      delegate;def each_cb(w: :T);generic_types :T; end
      
      def each_view(cb:each_cb)
        for i in 0..(length-1)
          cb(get(i))
        end
      end      
      
      def contains(v: :T) :bool
        c = false
        each_view() do |w| 
          if v==w
            c = true
            next
          end
        end
        return c
      end
      
      def set_named(n:string)
        self.view = @_named[n] if @_named[n] != nil
      end    
      
      def get_named(n:string) :'T?'
        return @_named[n]
      end
      
      def get_name(w: :T) :string?
        n = :string?
        @_named.keys.each do |k|
          if @_named[k] == w
            n = k
            return n
          end
        end
        return n
      end
      
      def iterator() :Iterator[:T]
        return Iterator[:T].new(self)
      end
      
      class Iterator
        generic_types :T
      
        @_index = 0
        @_tabbed = :Tabbed[:T]
        def self.new(t: :Tabbed[:T])
          @_tabbed = t
        end
        
        def next() :bool
          return @_index < @_tabbed.length
        end
        
        def get() :T
          @_index += 1
          return `_tabbed.get(_index-1)`
        end
      end
    end
  end
end