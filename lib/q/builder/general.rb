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
    
    def build_str ident = 0
      (" "*ident)+"#{start}:#{last}"
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
      "\n#{" "*ident}}\n"
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
      mark_no_semicolon true
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
  
  module Yield0
    def build_str ident = 0
      (" "*ident) + "yield" 
    end
  end

  module Yield
    def build_str ident = 0
      (" "*ident) + "yield "+
      args.map do |a| a.build_str(0).gsub(/\n$/,'') end.join(", ")
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
        
        unless args[1].is_a?(InitializerBlock)
          s=s.gsub(/\)$/,", ")+args[1].build_str(ident)+")"
        else
          s << " " + args[1].build_str(ident+2)
        end
        
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


  module EnumDeclaration
    def assignments
      args[0].find_all do |q| q.event == :assign end
    end
    
    def assignments_valid?
      z = assignments.find do |q| q.args[0].type != :constant end
      
      return true unless z
      
      QSexp.compile_error z.line, "Enum Members must be CONSTANT."
    end
    
    def build_str ident = 0
      assignments_valid?
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

  module InitializerBlock
    include Body
    def initialize *o
      super
      @body_stmt = args[1]
    end
    
    def build_str ident = 0
      "{\n" +
      @body_stmt.build_str(ident+2).gsub(/^\n/,'') +
      (" "*ident) + "}\n\n"
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
      "#{" "*ident}#{args[0].build_str}#{args[2].string}".gsub(/\-\@/,'-')
    end
  end

  module String
    def is_template?
      args[0].args.find do |a| a.is_a?(StringEmbedExpr) end
    end
  
    def build_str  ident=0
      (" "*ident)+"#{is_template? ? "@" : ""}\"" +
      args[0].args.map do |c| c.build_str().gsub(";\n",'') end.join+
      "\""
    end
  end
  
  module Break
    def build_str ident = 0
      (" "*ident)+"break"
    end
  end
  
  module OPAssign
    def build_str ident = 0
      (" "*ident) +
      args.map do |a| a.build_str() end.join(" ")
    end
  end
  
  module While
    def build_str ident = 0
      "\n"+(tab=" "*ident)+"while ("+
      args[0].build_str() + ") {\n" +
      args[1].build_str(ident+2) +
      tab+"}\n\n"
    end
  end
  
  module IFOP
    def build_str ident = 0
      (" "*ident) +
      args[0].build_str() + " ? " +
      args[1].build_str() + " : " +
      args[2].build_str()
    end
  end
  
  module StringEmbedExpr
    def build_str ident = 0
      (" "*ident)+"$("+super+")"
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

  module XString
    def build_str ident = 0
      args[0].children[0].string
    end
    
    def type
      build_str
    end
    
    def name
      build_str
    end
    
    def string
      build_str
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
