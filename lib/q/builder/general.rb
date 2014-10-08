module QSexp
  module Dot2
    attr_accessor :start, :last
    def initialize *o
      super
      
      on_parented do
        @start = args[0].build_str
        @last = args[1].build_str
      end
    end
  end

  module For
    attr_reader :name, :low, :high, :type
  # for (type name = low; name <= high; name++) {
  #
  # }

    def initialize *o
      super
      
      on_parented do
        args[1].parented self
        @name = args[0].build_str
        @low =  args[1].start
        @high = args[1].last
      end
    end

    def build_str ident = 0
      "\n#{" "*ident}for (#{type || :int} #{name} = #{low}; #{name} <= #{high}; #{name}++) {\n"+
        args[2].build_str(ident+2)+
      "\n#{" "*ident}}"
    end
  end


  module Array
    def initialize *o
      super
    end
    
    def build_str ident = 0
      "#{" "*ident}{"+args[0].children.map do |c| c.build_str() end.join(", ")+"}"
    end
  end

  module Super
    def build_str ident = 0
      "#{" "*ident}base(#{args[0].build_str})"
    end
  end

  module ZSuper
    def build_str ident = 0
      "#{" "*ident}base"
    end
  end

  module Program
    include Body
    def initialize *o
      super
      @body_stmt = args[0]
      @args.map do |a|
        a = self.parented(nil)
      end
    end
  end


  module IfElse
    attr_reader :else_stmt
    def initialize *o
      super
      @else_stmt = args[2]
    end
    
    def build_str ident = 0
       s = "if (#{args[0].build_str}) {\n" +
       args[1].build_str(ident+2) +
      "\n#{" "*ident}} "  
    
      if else_stmt
        s << else_stmt.build_str(ident).gsub(Regexp.new("^#{" "*ident}els"),' els')
      end
      
      return s
    end
  end

  module If
    include IfElse
    
    def build_str ident = 0
      "\n#{tab=" "*ident}" + super
    end
  end

  module ElsIf
    include IfElse
    def build_str ident = 0
      s= "else " + super
    end  
  end

  module Else
    def build_str ident = 0
      "#{tab=" "*ident}else {\n#{args[0].build_str(ident+2)}#{tab=" "*ident}}\n"
    end
  end



  module Return0
    def build_str ident = 0
      (" "*ident) + "return" 
    end
  end

  module Return
    def build_str ident = 0
      (" "*ident) + "return("+
      args.map do |a| a.build_str(0).gsub(/\n$/,'') end.join(", ")+
      ")"
    end
  end

  module Next
    def build_str ident = 0
      (" "*ident) + "return("+
      args.map do |a| a.build_str(0).gsub(/\n$/,'') end.join(", ")+
      ")"
    end    
  end 



  module Each
  end

  module Binary
    def build_str ident = 0
      super(0)
    end
  end

  module MethodAddBlock
    def initialize *o
      super
      on_parented do
      if !args[0].args[0]
        extend Each
        if args[0].args[1] and args[0].args[1].is_a?(Item)
          args[1].delegate_type = args[0].args[1].build_str().gsub(";\n",'').to_sym
          args[0].args[1] = nil
        end
      end
      end
    end
    def build_str ident = 0
      if args.length > 1
        s=args[0].build_str(ident)
        s=s.gsub(/\)$/,", ")+args[1].build_str(ident)+")"

        # proc block to closure
        if !args[0].args[0]
          s=s.strip.gsub(/\(, /,'').gsub(/}\)$/,"}").gsub(Regexp.new("^#{" "*(ident*2)}"),'    ')
        elsif !args[0].args[1].args[0]
          s=(" "*ident)+s.strip.gsub(/\(, /,'(').gsub(/}\)$/,"})")
        end
      
        s
      else
        super
      end
      
    rescue => e
      raise "LINE: #{line}, #{event}\n#{e}\n#{e.backtrace[0..3].join("\n")}"
    end
  end


  class ::Object
    def build_str(ident=0)
      ""
    end 
  end

  class ::Array
    def parented q
      each do |a|
        a.parented q
      end
    end
  end

  class ::Symbol  
    def build_str ident=0
      "#{" "*ident}#{self}"
    end
    def parented *o
    
    end
  end

  class ::Symbol
    def write buff = QSexp::BUFFER, ident=0
      buff << "#{" "*ident}#{self}"
    end
  end



  module Numeric
    def resolved_type
      case args[2].string
      when "f"
        :float
      when "d"
        :double
      end
    end
    
    def build_str ident = 0
      "#{" "*ident}#{args[0].string}#{args[2].string}"
    end
  end

  module String
    def build_str  ident=0
      '"'+super(ident)+'"'
    end
  end

  module MethodAddArg
    def build_str ident = 0
      "#{" "*ident}"+args[0].build_str(0) + 
      (args[0].is_a?(Cast) ? "#{args[1].build_str.gsub(";\n",'')}" : "(#{args[1].build_str.gsub(";\n",'')})")
    rescue => e
      puts "LINE: #{line}, EVENT: #{event}: #{args[0].event} ****"
      raise e
    end
  end


  module ArgsAddBlock
    def build_str ident = 0
      args[0].build_str.gsub(";\n",', ').gsub(/\, $/,'')
    end
  end


  module ConstPathRef
    def build_str ident = 0
      args.map do |a| a.build_str end.join(".")
    end
    
    def resolved_type
      build_str
    end
  end



  module ARef
    def build_str ident = 0
      (" "*ident) +
      args[0].build_str + "[" +
      args[1].build_str +
      "]"
    end
  end



  module Cast
    def build_str ident=0
      "("+args[0].string+") "
    end
  end
end
