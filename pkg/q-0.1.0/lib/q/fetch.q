Q::package(:'gio-2.0')
require "Q/stdlib/file"
namespace module Q
namespace module Fetch
  def self.uri(src:string, dest: :string?, basename: :string?) :string
    outf = :string
    b    = basename != nil ? basename : Q::File.basename(src)
    
    if dest == nil
      outf = "./#{b}"
    else
      outf = "#{dest}/#{b}"
    end
    
    f = `GLib.File.new_for_uri(src)`
    w = `GLib.File.new_for_path(outf)`;
    
    f.copy(w, FileCopyFlags::NONE, nil, nil);
    
    return b
  end
end
end
