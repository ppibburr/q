require "Q"
using Q

Q::package(:'libsoup-2.4')
Q::flags(:'--thread')

namespace module Quincy
  class MimeTypeQuery
    @types = :Hash[:string, :string?]
    :MimeTypeQuery[@@singleton]
    
    def self.new()
      @types = Hash[:string, :string?].new()
      @types["txt"]   = "text/plain"
      @types["html"]  = "text/html"
      @types["xhtml"] = "application/xhtml+xml"
      @types["html"]  = "application/xml"          
      @types["js"]    = "application/javascript"
      @types["json"]  = "application/json"
      @types["png"]   = "image/png"                              
      @types["jpg"]   = "image/jpeg"
      @types["gif"]   = "image/gif"
      @types["md"]    = "text/plain"
      @types["gemspec"] = "text/plain"
      @types["q"]       = "text/plain"
      @types["c"]       = "text/plain"
      @types["cpp"]     = "text/plain"
      @types["h"]       = "text/plain"
      @types["yaml"]    = "text/plain"
      @types["cfg"]     = "text/plain"
      @types["conf"]    = "text/plain"
      @types["sh"]      = "text/plain"
      @types["bat"]     = "text/plain"      
      @types["ruby"]    = "application/x-ruby" 
    end

    def guess(f:string) :string?
      chunks = f.split(".")
        
      ext=chunks[chunks.length-1]
      return @types[ext]
    end

    def register_type(e:string, t:string)
      @types[e] = t
    end 

    def self.for_path(path:string) :string?
      init()
      return @@singleton.guess(path)
    end

    def self.add_type(e:string, t:string)
      init()
      @@singleton.register_type(e,t)
    end

    def self.init()
      @@singleton ||= MimeTypeQuery.new()
    end
  end

  class Match
    :string[@path, @base_dir, @query, @method]
    @message = :Soup::Message
    @uri = :string
    @match_data = :string[]
    @params = :HashTable[:string, :string?]

    attr_accessor mime_type:string, md: :string[], rendered: :uint8[]
    def self.new(path:string, base_dir:string)
      @path = path
      @base_dir = base_dir
      @mime_type = "text/html"    
    end
    
    def render_file(path:string, mt: :string?) :string?
      f = Q::File.join(base_dir, path)

      if Q::File.exist?(f)
        if mt == nil
          self.mime_type = MimeTypeQuery.for_path(f)
          
          self.mime_type = "application/octet-stream" if self.mime_type == nil
        end

        return Q.read(f)
      end
    end

    def request_body() :string?
      return :string << message.request_body.flatten().get_as_bytes().get_data()
    end

    def param(n:string) :string?
      if @params != nil
        return @params[n]
      end
      return nil
    end
  end

  class Route
    @block  = :Quincy::App::cb
    @regexp = :Regex?
  end

  class App
    :'Soup.Server'[@server]
    @routes = :Routes
    @loop = :MainLoop  
    attr_accessor base_dir: :string?
    attr_accessor port: :uint

    delegate;
    def cb(resp:Match) :string?
    end

    delegate;
    def runner(app:App); end    

    class Routes
      attr_accessor get: :Hash[:string, :Route?], post: :Hash[:string, :Route?]
      def self.new()
         @get  = Hash[:string, :Route?].new()
         @post = Hash[:string, :Route?].new()
      end
    end
    
    def get(path:string, block:cb)
      `routes.get[path] = new Route();`
      `routes.get[path].block = block;`
      @server.add_handler(path, handler)
    end

    def getx(path:string, block:cb)
      get(path,block)
      begin
        @routes.get[path].regexp = Regex.new(path)
      rescue RegexError => e
        puts e.message
      end
    end

    def post(path:string, block:cb)
      @routes.post[path] = Route.new();
      @routes.post[path].block = block;
      @server.add_handler(path, handler)
    end

    def postx(path:string, block:cb)
      post(path,block)
      begin
        @routes.post[path].regexp = Regex.new(path)
      rescue RegexError => e
        puts e.message
      end
    end
    
    def four0four(msg: :Soup::Message)
      msg.set_response("text/html", Soup::MemoryUse::COPY, "That's and error, Jim.".data)
    end
    
    def handler(server: :Soup::Server, msg: :Soup::Message, path:string, query: :GLib::HashTable?, client: :Soup::ClientContext) :void
      md = :MatchInfo?
      m  = :Route?
      p  = :string[0]
            
      print "[#{DateTime.new_now_local()}] Request: #{path} -> "

      if msg.method == "POST"
        m = @routes.post[path]
      elsif msg.method == "GET"
        m = @routes.get[path]
      end

      if nil == m
        `Hash<string, Route?>? mr = null;`
        if msg.method == "POST"
          `mr = this.routes.post;`
        elsif msg.method == "GET"
          `mr = this.routes.get;`
        end
      
        mr.keys().each do |t|
          r = mr[t]
          if (:Route << r).regexp != nil
            if (:Route << r).regexp.match(path, 0, :out.md)
              m = :Route << r 
              break
            end
          end
        end

        if m == nil
          puts "not found (404)."
          four0four(msg)
          return;
        end
        
        ma=md.fetch_all()
        i = 0

        ma.each do |s|
          p << s if i > 0
          i+=1 
        end
      end

      match              = Match.new(path, base_dir)
      match.message      = msg
      match.params       = query
      match.query        = msg.uri.get_query()
      match.match_data   = p
      match.method       = msg.method

      result = m.block(match)
      if result == nil
      
        msg.set_status(404)
        four0four(msg)
        puts "NotFound (404)."
      else
      
        match.rendered = result.data
        print "mime_type: #{match.mime_type} "
        puts  "200 OK."
        msg.set_status(200)
        msg.set_response(match.mime_type, Soup::MemoryUse::COPY, match.rendered)      
      end
    end

    def run(r: :runner?)
      r(self) if r != nil
      puts "Quincy wakes up @ #{port}...\nServing your brew."

      begin
        server.listen_all(port,0);
        @loop = Q.main()
      rescue Error => e
        puts "UhOh... #{e.message}"
      end
    end 

    def self.new()
      @server = Soup::Server.new("server_header","quincy-app");    
      @base_dir = "./"
      @routes = Routes.new()
    end
  end

  @@app = :App?
  
  def self.init() :App?
    if @@app == nil
      @@app = Quincy::App.new()
    end
    return @@app
  end

  def self.run(port:uint, r: :Quincy::App::runner)
    quincy = Quincy::App.new()
    quincy.port = port
    quincy.run(r)
  end  
end

