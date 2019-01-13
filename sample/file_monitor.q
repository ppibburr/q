require "Q"

Q.main() do
  Q::File.created('./') do |src|
    puts "Created: #{src.get_path()}"
    Q.quit()
  end
end
