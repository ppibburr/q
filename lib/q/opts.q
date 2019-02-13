require "Q"
require "Q/stdlib/hash"
Q.adddef Q_FILE
Q.reqifdef Q_FILE, "Q/stdlib/file"

Q::package(:'posix')

using Q
class Opts
  class Option
    :string?[@desc, @name,@short_name]
    @vtype = :Type?
    @value = :Value?
  
    def self.new(n:string, d: :string?, t: :Type?, v: :Value?)
      @desc = d
      @name = n
      @vtype = t
      @value = v
    end
    
    def parse(v:string)
      @value = int.parse(v) if vtype == typeof(:int)
      @value = bool.parse(v) if vtype == typeof(:bool)      
      @value = v.to_double() if vtype == typeof(:float)
      @value = v.to_double() if vtype == typeof(:double)      
      @value = v if vtype == typeof(:string)
      @value = v if vtype == typeof(:Q::File)      
    end
    
    signal;def on(v: :Value?); end
  end

  :string?[@program, @summary] 
  def self.new()
    @opts = Hash[:Option].new()
    
    h = add("help","Show help message.")
    h.short_name = "h"
  end
  
  @opts = :Hash[:Option]
  def add(n:string, desc: :string?, t: :Type?, v: :Value?) :Option
    @opts[n] = Option.new(n, desc, t, v)
    return @opts[n]
  end 
  
  def parse(argv: :string[])
    @program = argv[0]
    aa = :string[0]
    
    (argv.length-1).times do |i|
      if i != 0
        o = :Opts::Option?
        a = argv[i]
        
        if a =~ /^\-\-(.*?)\=(.*)/
          o=@opts[$1]
          invalid($1) if o == nil
          o.parse(Shell.unquote($2)) if o != nil
        elsif a =~ /^\-\-(.*)/
          o=@opts[$1]
          invalid($1) if o == nil
        elsif a =~ /^\-(.*)/
          opts.for_each() do |k,v|
            o = v if v.short_name == $1
            next if o!=nil
          end
          invalid($1) if o == nil
        else
          exp = Q::File.expand_path(a, cl.get_cwd())
          fa = Q::Dir.glob(exp)
          for f in fa
            aa << f
          end
          aa << exp if fa.length == 0
        end 
        
        o.on(o.value) if o!=nil
      end
    end
    return aa
  end
  
  def type_name(o:string) :string
    if opts[o].vtype == typeof(:string)
      return "STRING"
    elsif opts[o].vtype == typeof(:Q::File)
      return "FILE"
    elsif opts[o].vtype == typeof(:bool)
      return "BOOL"
    elsif opts[o].vtype == typeof(:int)
      return "INTEGER"
    elsif opts[o].vtype == typeof(:double)
      return "DOUBLE"      
    elsif opts[o].vtype == typeof(:float)
      return "FLOAT"
    end
    
    return opts[o].vtype.name()
  end
  
  def option(o:string) :Option?
    return opts[o]
  end
  
  def help()
    s = ""
    s << hint  + "  
    
#{summary == nil ? "" : summary}    
    "
    s << "\nOPTIONS"
    for o in opts.keys
      if opts[o].vtype == nil
        s << "\n  %-40s %s".printf("#{opts[o].short_name != nil ? "-"+opts[o].short_name+", " : ""}--"+opts[o].name, opts[o].desc)
      else
        s << "\n  %-40s %s".printf("--#{opts[o].name}=#{type_name(o)}", opts[o].desc)
      end
    end
    s << "\n"
    return s
  end
  
  def get(o:string) :Option?
    return @opts[o]
  end
  
  def set(o:string, v: :Option?)
    @opts[o] = v
  end
  
  def contains(o:string) :bool
    return `o in opts.keys`
  end
  
  `private string? _hint;`
  property hint:string do
    get do :owned;return @_hint == nil ? "Usage:  #{program} [OPTIONS] [FILEs]" : @_hint end
    set do @_hint = value end
  end
  
  signal;def invalid(s:string); end
end



`#if Q_TEST`
def main(argv: :string[])
  opts = Opts.new()

  opts.summary = "An example program."

  opts["help"].on.connect() do puts opts.help(); exit(0); end

  o=opts.add('test-int', "test int value.",typeof(:int)).on.connect() do |v| 
    puts :int > v if v!=nil
  end
  
  d = :Value; d= 5
  o=opts.add('test-int-def', "test int value.",typeof(:int), d).on.connect() do |v| 
    puts :int > v if v!=nil
  end  
  
  o=opts.add('test-str', "test str value.",typeof(:string)).on.connect() do |v| 
    puts Q.expand_path(:string > v) if v!=nil
  end  

  o=opts.add('test-file', "test file value.",typeof(:Q::File)).on.connect() do |v| 
    puts Q.expand_path(:string > v) if v!=nil
  end
  
  opts.invalid.connect() do |o|
    puts "Invalid option: #{o}"; exit(1)
  end
  
  opts.parse(argv).each do |f| puts "FILE: #{f}" end
  
  puts :int > opts.option("test-int-def").value
end
`#endif`
