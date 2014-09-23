module Q
	class Base
	  attr_accessor :last_infered_type
	  attr_reader :sexp, :lvars, :ident
	  def initialize buff, sexp, ident = 0
      @sexp = sexp
      @ident = ident
      @lvars = {}
      @buff = buff
      
      if sexp[1].is_a?(Array)
        sexp[1].each do |q|
          build_ksexp(q)
          next_sexp
        end
      end
	  end
	  
	  def newline(i=-1)
      @buff[i] ? @buff[i] << "\n" : nil
	  end
	  
	  def next_sexp
	  
	  end
	  
	  def build_ksexp ss, ident=@ident
      case ss[0]
      when :class
        begin
          sc = ss[2][1][1]
        rescue;end
        
        @buff << "class #{ss[1][1][1]}#{sc ? " : #{sc}" : ""} {"
        newline
        
        k = Q::Class.new(@buff, ss[3], ident+2)
        @buff << "}"
        newline
      
      when :assign
        case ss[1][0]
        when :var_field
          case ss[1][1][0]
          when :"@ident"
            if lvars[ss[1][1][1]]
            else
              @buff << "#{" "*ident}var "
            end
          end
        else
      
        end
        
        build_ksexp ss[1][1],0
        
        @buff << " = "

        if ss[2].last[1] == "new"
          ss[2][-1][1] = ""
          ss[2][-2] == ""
          @buff << "new "
        elsif ss[2][0] == :method_add_arg and ss[2][1].last[1] == "new"
          ss[2][1][-1][1] = ""
          ss[2][1][-2] = ""        
          @buff << "new "
        end
        
        o = @ident
        @ident = 0      
        build_ksexp ss[2],0
        @ident = o
      when :command
        raise "TODO: :command"
      when :fcall
        if ss[1][1] == "printf"
          ss[1][1] = "stdout.printf"
        
        elsif ss[1][1] == "print"
          ss[1][1] = "stdout.printf"
        end        

        @buff << (" "*ident)+ss[1][1]
      when :vcall
        @buff << (" "*ident)+ss[1][1]
      when :call
        build_ksexp ss[1]

        n = @buff.length-1
        @buff[n] = @buff[n].gsub(";",'')
        @buff[n] += "#{ss[2]}"+ss[3][1]
      when :string_literal
        @buff << "\"#{ss[1][1][1]}\""
      when :args_add_block
        ss[1].each_with_index do |a,i|
          build_ksexp(a,0)
          @buff.last << "," unless i == ss[1].length-1
        end
      when :paren
        @buff.last << "("
        
        ss[1].each do |s|
          build_ksexp s,0
        end
        
        @buff.last << ")"
      when :method_add_arg
        build_ksexp ss[1]
        build_ksexp ss[2]
      when :arg_paren
        @buff << "("
        build_ksexp(ss[1], 0) if ss[1]
        @buff << ")"
      when :def
        @buff << ""
        q = @buff.length-1
        
        if ss[2][0][0] == :paren
          ss[2][0] = ss[2][0][1]
        end
        
        m = Q::Method.new(@buff, ss[2], ss[3],ident+2)
        t = m.explicit_return_type || m.last_infered_type
        w = []
        
        m.arg_names.each_with_index do |n,i|
          w << "#{m.arg_types[i]} #{n}"
        end
        
        @buff[q] = "#{" "*ident}public #{t} #{ss[1][1]} (#{w.join(", ")}) {"
        newline(q)
        
        @buff << "#{" "*ident}}"  
        newline  
      when :var_ref
        q = ss[1][1]
        q == "self" ? "this" : q
        @buff << "#{" "*ident}#{q};"
      when :return
        @buff << "#{" "*ident}return "
        build_ksexp ss[1],0
      when :binary
        binary(ss)
      else
        if ss[0].is_a?(Array)
          build_ksexp(ss[0],0)
        elsif ss[0] =~ /^\@/
          @buff << ss[1]
        end
      end
	  end
	  
	  def binary s
      s.shift
      s.each_with_index do |q,i|
        if i.even?
          build_ksexp q,0
        else
          @buff.last << " #{q} "
        end
      end
	  end
	end

	class Body < Base
	  def next_sexp
      @buff.last << ";" unless @buff.empty? or @buff.last[-1] == "\n"
      newline
	  end
	end

	class Program < Body
	end

	class Q::Method < Body
	  attr_reader :two
	  attr_reader :infered_return_type
	  attr_reader :explicit_return_type
	  attr_reader :arg_types
	  attr_reader :arg_names
    def initialize buff, two, sexp, ident=0
      @buff = buff
      @two = two
      @arg_types = []
      @arg_names = []
      n = two.find do |q| q.is_a?(Array) end

      if sexp[1][0].is_a?(Array) and sexp[1][0][0] == :symbol_literal
        rt = sexp[1].shift
        @explicit_return_type = rt[1][1][1]
      end
      
      n[5].each do |l|
        raise unless l[0][0] == :"@label"
        t = l[0][1].gsub(":",'')
        arg_types << t
        arg_names << l[1][1][1] 
      end if n[5]
     
      super buff, sexp, ident
	  end
	end

	class Class < Body

	end
  
  def self.translate code
    Q::Program.new(out = [],Ripper::sexp(code))
    out.join
  end
end


