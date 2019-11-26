require "Q/main"
require "Q/stdlib/dir"
require "Q/stdlib/file"

Q.main() do
  Q::Dir.created('./') do |src|
    puts "Created: #{src.get_path()}"
    Q.quit()
  end
  
  Q.idle() do
    Q.write("./test.txt", "test\n")
    next false
  end
end
