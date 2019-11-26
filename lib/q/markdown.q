Q::package(:'discount')
Q::flags(:"-X -lmarkdown")
require "Q"
namespace module Q
  class MarkDown
    def self.render(s:string) :string?
      out = :string?
      doc=Markdown::Document.new_gfm_format(s.data, 0x02000000)
      doc.compile(0x02000000)
      doc.get_document(:out > out)
      puts out
      return out
    end
  end
end
