GLib::FileUtils.set_contents("data.txt", "foo bar!\n")

contents = :string
GLib::FileUtils.get_contents("data.txt", contents.out!)
print(contents)

GLib::FileUtils.remove("data.txt")
