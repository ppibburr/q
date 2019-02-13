Q::package(:'gtksourceview-3.0')

require "Q/edit/editor"

namespace module Q
  namespace module Edit
    class Session
      def self.restore(editor:Editor)
        files = Q::read(editor.session).split("\n")

        editor.each_view() do |v|
          if !(`v.edit_view.path_name in files`)
            editor.close_view(v)
          end
        end
        
        files.each do |f| editor.open_file(f) end 
      end

      def self.clear(editor:Editor)
        Q::File.write(editor.session, "")
      end
      
      def self.save(editor:Editor)
        list = ""
        
        for i in 0..(editor.book.get_n_pages()-1)
          list << "\n" if i > 0
          list << editor.get_nth_view(i).path_name
        end
        
        Q::File.write(editor.session, list)
      end
      
      def self.list_active(editor:Editor) :string
        list = :string[0]
        
        for i in 0..(editor.book.get_n_pages()-1)
          list << editor.get_nth_view(i).path_name
        end
        
        return string.joinv(" ", list)
      end
      
      def self.list(editor:Editor) :string
        return string.joinv(" ", Q::read(editor.session).split("\n"))
      end
    end

    class WordProvider
      @keyword_complete = :Gtk::SourceCompletionWords
      @buffer           = :Gtk::SourceBuffer
      
      def self.new(words:string)
        @buffer = Gtk::SourceBuffer.new(nil)

        self.words = words

        @keyword_complete = Gtk::SourceCompletionWords.new('keyword', nil)
        keyword_complete.register(buffer)
      end
      
      def attach(view:EditView)
        view.get_completion().add_provider(keyword_complete)
      end

      property words:string do
        get do :owned
          return buffer.text
        end

        set do
          buffer.begin_not_undoable_action()
          buffer.set_text(value)
          buffer.end_not_undoable_action()
        end 
      end

      `private static WordProvider? _q;`
      def self.q() :WordProvider
        `_q = new WordProvider(Q_KEYWORDS)` if _q == nil
        return _q
      end
    end

    Q_KEYWORDS = "EditView EditWidget Source SourceView SourceCompletionProvider SourceBuffer SourceSearchContext signal delegate async virtual override abstract hide namespace module class enum struct for def if end __FILE__ DATA GLib Gtk Gdk File Hash Window Button Toolbar ToolButton Box DrawingArea system read open Label property attr_reader attr_writer attr_accessor each in new initialize send FileUtils chmod mkdir write WebKit WebView WebFrame Frame Pane Notebook add set get"
  end
end


