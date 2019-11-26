require "Q/jsc"
Q::package(:"webkit2gtk-web-extension-4.0")
Q::package(:"javascriptcoregtk-4.0")
Q::package(:"jsc")

`
[CCode (cname="webkit_frame_get_js_context")]
extern JSC.Context get_js_context(WebKit.Frame f);
`

def webkit_web_extension_initialize_with_user_data(extension: :WebKit::WebExtension, data: :Variant?)
  extension.page_created.connect() do |page|
    c = get_js_context(page.get_main_frame())
    puts Q::JS.mkobject(c, data.get_string())["foo"]
    message("Page %" + uint64.FORMAT + " created", page.get_id());
    page.document_loaded.connect() do      
      Q::JS.init(c)
      c.eval("
        QJs.puts('test');
        form = document.getElementsByTagName('form')[0];
        e = form.querySelector('input[name=\"username\"]');
        e.value = 'ppibburr'; 
        QJs.puts(e);
      ")
    end
  end
end
