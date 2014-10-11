module QSexp
   def self.compile_error line, msg
     puts "LINE: #{line} - #{msg}"
     exit 1
   end

	module Node
	  attr_accessor :parent, :line
	  def initialize l, p = nil
		@parent = p
	  	@line = l
	  end
	  
    def mark_no_semicolon(bool = true)
      @marked_no_sc = bool
    end
    
    def marked_no_semicolon?
      @marked_no_sc
    end
    
	  def get_scope
      p = self
      until p.respond_to? :scope
        p = p.parent
        break unless p
      end

      return p.scope
    end
      
      def get_scope_type
        if s=get_scope
          if s.is_a?(ClassScope)
            scope = :class
          elsif s.is_a?(NamespaceScope)
            scope = :namespace   
          elsif s.is_a?(ProgramScope)
            scope = :program      
          else
            scope = :generic
          end
        end
        
        return scope      
      end
    
    def parented p
      @parent = p
      @on_parented_cb.call(p) if @on_parented_cb
      if (a=@children);
        a.each do |c| c.parented(self) if c end
      end
      if (a=@args);
        a.each do |c| c.parented(self) if c end
      end      
    end
    
    def on_parented &b
      @on_parented_cb = b
    end
    
    def write buff = QSexp::BUFFER, ident=0
      buff << build_str(ident)

    end
	end  

	module Event
	  attr_accessor :event
	  def initialize e, l, *o
		  @event = e
		  super l, *o
	  end
	end
	  
	  
	class Statements
	  include Node
	  
	  attr_reader :children, :event
	  
	  def push i      
		  (@children ||= []) << i
	  end
    
    def build_str ident=0
      str = ""
      children.each do |c|
        str << c.build_str(ident).to_s+"#{(c.is_a?(Body) or c.is_a?(For) or c.is_a?(Each) or c.marked_no_semicolon?) ? "" : ";"}\n"
        str.replace("\n") if str.strip == ";"
      end if children
      str.gsub(/^;\n/,'')
    end
	end

	class Item
	  include Node
	  include Event
	  attr_reader :args
	  
	  def initialize e, line ,*a
		  super e,line
      
      a.each do |q| 
        q.parent = self if q.is_a?(Node)
      end
		  
      @args = a
	  end
    
    def push q
      @args << q
    end
    
    def build_str ident=0
      z = []
      args.each do |a|
        if a
          unless a.is_a?(Array)
            a.write z,ident
          else
            a.each do |q| q.write z,ident end
          end
        end
      end
      z.join
    end
    
    CASTS = [
      :char,
      :uchar,
      :int,
      :uint,
      :long,
      :flt,
      :double,
      :string
    ]
    
    def self.new e, *o
      if QSexp::Property.match? e, *o
        return construct(QSexp::Property, e, *o)
      end
    
      case e
      when :symbol_literal
        return construct(QSexp::DeclaredType, e ,*o)
      when :const_path_ref
        construct QSexp::ConstPathRef, e, *o
      when :binary
        construct QSexp::Binary, e, *o
      when :call
        
        if o[1].is_a?(Single) and o[3].event == :"@ident" and ["d","f", "l"].index(o[3].string)
          if [:float, :int].index(o[1].resolved_type)
            return construct(QSexp::Numeric, e, *o)
          end
        end
        
        if New.match?(*o)
          return construct(QSexp::New, e ,*o)
        end        
        
        return construct(QSexp::Call, e, *o)

        
      when :sclass
        return construct(QSexp::ClassConstruct, e, *o)    
        
      when :defs
        if o[3].string == "construct"
          return construct(QSexp::StaticConstruct, e, *o)
        end
      
        if Constructor.match?(*o)
          return construct(QSexp::Constructor, e, *o)
        end      
      
        return construct(QSexp::Defs, e, *o)  
        
      when :method_add_arg
        construct(QSexp::MethodAddArg, e, *o)
        
      when :method_add_block
        construct(QSexp::MethodAddBlock, e, *o)
        
        
      when :fcall
        if o[1].type == :local
          if CASTS.index(o[1].string.to_sym)
            construct(QSexp::Cast, e, *o)
          elsif o[1].string == "proc";
            return nil    
          else
            construct(QSexp::FCall, e, *o)  
          end
        end
      when :aref
        if GenericsTypeDeclaration.match? *o
          return construct(GenericsTypeDeclaration, e, *o)
        end
        construct ARef, e, *o
      when :params
        construct(QSexp::Parameters, e, *o)   
      when :def
        if o[1].string == "initialize"
          return construct(Construct, e, *o)
        end
        
        construct(QSexp::Def, e, *o)       
      when :assign
        construct(QSexp::Assignment, e, *o)
      when :program
        construct(QSexp::Program, e, *o)
      when :class  
        construct(QSexp::Class, e, *o)        
      when :do_block
        construct(QSexp::Block, e, *o)  
      when :array   
        construct(QSexp::Array, e, *o)        
      when :var_field  
        construct(QSexp::VarField, e, *o)  
      when :var_ref
        construct(QSexp::VarRef, e, *o)  
      when :vcall
        if MemberModifier::FLAGS.index(o[1].string.to_sym)
          return construct(QSexp::MemberModifier, e, *o)
        end
        
        construct(QSexp::VCall, e, *o)         
        
      when :super
        construct QSexp::Super, e, *o 
      when :zsuper
        construct QSexp::ZSuper, e, *o 
                         
      when :string_literal
        construct(QSexp::String, e, *o)     
      when :dot2
        construct(QSexp::Dot2, e ,*o)
      when :for
        construct(QSexp::For, e, *o)  
      when :args_add_block 
        construct(QSexp::ArgsAddBlock, e, *o)    
      when :if
        construct(QSexp::If, e, *o)
      when :elsif
        construct(QSexp::ElsIf, e, *o)
      when :else
        construct(QSexp::Else, e, *o)                
      when :command;
        if o[1].string == "namespace"
          construct(QSexp::Namespace, e, *o)
        elsif ClassGenericsDeclaration.match? *o
          construct ClassGenericsDeclaration, e, *o
        else
          construct(QSexp::FCall, e, *o) 
        end
      when :xstring
        construct(QSexp::XString, e, *o)
      when :return0
        construct(QSexp::Return0, e, *o)
      when :return
        construct(QSexp::Return, e, *o)
      when :next
        construct(QSexp::Next, e, *o)            
      else
        return super
      end
    end
    
    def self.construct mod, e, *o
      k = ::Class.new(self)
      k.class_eval do
        include mod
      end
      
      ins = k.allocate
      ins.send :initialize, e,*o
      return ins
    end
	end

	class Single
	  include Node
	  include Event
	  attr_reader :string
	  def initialize e, l, t
		  super(e, l)
		 
		  @string = t == "nil" ? "null" : t
	  end
	  
	  def resolved_type
	    case event
	    when :"@int"
	      :int
	    when :"@float"
	      :float
	    when :"string_literal"
	      :string
	    end
	  end
	  
	  def type
      case event
      when :"@gvar"
        :class
      when :"@cvar"
        :static
      when :"@ivar"
        :instance
      when :"@const"
        :constant
      when :"@ident"
        :local
      when :"@kw"
        :keyword
      end
	  end    
    
    def build_str ident=0
      "#{" "*ident}#{string}"
    end
	end
end
