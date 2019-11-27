Q::package(:"webkit2gtk-4.0")
Q.adddef Q_STD
require "Q/markdown"
require "Q/resource"

namespace module Q
  class MarkDownViewer < Gtk::Bin
    @_webview = :WebKit::WebView
    attr_reader resource_path:string
    def self.new(s: :string?)
      @_resource_path = "#{Q.env()['HOME']}/.local/lib/q-markdown-viewer"
    
      Q::Resource.new('http://cdnjs.cloudflare.com/ajax/libs/highlight.js/9.15.6/styles/default.min.css', "#{@resource_path}/default.min.css")
      Q::Resource.new('http://cdnjs.cloudflare.com/ajax/libs/highlight.js/9.15.6/highlight.min.js', "#{@resource_path}/highlight.min.js")
      Q::Resource.new('https://raw.githubusercontent.com/highlightjs/highlight.js/master/src/styles/github.css', "#{@resource_path}/github.css")

      @_webview = WebKit::WebView.new()
    
      if s != nil
        render(s)
      end
    
      add(@_webview)
    
      show_all()
    end
    
    def render(s:string)
    code =  "<html><head>
    <link rel='stylesheet' href='file://#{@resource_path}/github.css'>
    <link rel='stylesheet' href='file://#{@resource_path}/default.min.css'>
    
    <script src='#{@resource_path}/highlight.min.js'>
    </script>
    
    <script>
      hljs.initHighlightingOnLoad()
    </script>
    
    </head><body><div class='markdown-body'>
    #{Q::MarkDown.render(s)}
    </div></body></html>";
    
      @_webview.load_html(code, "file:///")
    end
  end
end

def main(argv: :string[])
  Gtk.init(:ref > argv)
  w = Gtk::Window.new()
  w.resize(800,600)
  s = "#{DATA}"
  puts s

  w.add(Q::MarkDownViewer.new(s))
  w.show_all()
  Gtk.main()
end
__END__

#foo
foo **bar**  

```ruby
class Foo
  def bar i=9
    @bar = i
  end
end
```
