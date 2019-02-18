Q::package(:"webkit2gtk-web-extension-4.0")
Q::package(:"javascriptcoregtk-4.0")


def webkit_web_extension_initialize_with_user_data(extension: :WebKit::WebExtension, data: :Variant?)
  extension.page_created.connect() do |page|
    message("Page %" + uint64.FORMAT + " created", page.get_id());
    page.document_loaded.connect() do
      page.get_dom_document().document_element.inner_html = "hello from extension"
      
      c = page.get_main_frame().get_js_context()
      
      f = JSC::Value.new_function_variadic(c, "test", proc do |a| 
        print "Q func got: "
        puts :JSC::Value > a.index(0) ; return :'void*' > "from Q".dup() end, nil, typeof(:string))
      
      c.set_value("f", f)
      
      v = c.evaluate("f(1);", -1)
      puts v
      
      v = c.evaluate("a=window;a;",-1)
      l = JSC::Value.new_string(c, "test")
      
      v.object_set_property("foo", l)
      
      puts c.get_value("foo")

      c.get_value("f").function_call(typeof(:string), 'foo')
      
      o = c.get_value("Object").constructor_call()
      o.object_set_property("foo", JSC::Value.new_string(c,"bar"))
      puts o
      n = JSC::Context.new()
      puts n.get_value("Object")
    end
  end
end