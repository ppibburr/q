require "Q/uincy/simple"

port(8080)
base_dir("../..")
# add_mimetype("3g", "foo/ggg")

get("/") do |match|
  next "<h1>Hello <i>World!</i></h1><br><pre><code>#{escape_html(Q.read(__FILE__))}</pre></code>"
end

get("/hello") do |match|
  name = (param("name") != nil) ? param("name") : "nobody"
  
  next "<h1>Hello <i>#{name}</i></h1>"
end

postx("/(.*)") do |match|
  puts param("foo") if param("foo") != nil
  puts match.request_body()
  next ""
end
