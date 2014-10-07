module QSexp
  module New
    attr_reader :method, :type
    def self.match? *o
      (o[1].event == :var_ref or o[1].event == :const_path_ref or o[1].event == :aref) and (o[3].string == "new" or o[3].string =~ /^new_/)
    end
    
    def generics?
      args[0].event == :aref
    end
    
    def initialize *o
      super
      
      if !generics?
        @type = args[0].build_str
      else
        @type = args[0].args[0].build_str +
        "<"+
        args[0].args[1].args[0].children.map do |c| c.build_str end.join(", ") +
        ">"
      end
      
      if args[2].build_str =~ /^new\_/
        @method = args[2].build_str.gsub(/^new\_/, "")
      elsif args[2].build_str =~ /^new/
        @method = args[2].build_str.gsub(/^new/, "")
      end
      
      @method = nil if @method == ""
      
      on_parented do |p|
        def p.build_str ident = 0
          args[0].build_str ident
        end
      end
    end
    
    def build_str ident = 0
      "new #{type}#{method ? ".#{method}" : ""}(#{parent.args[1].build_str()})";
    end
  end
end
