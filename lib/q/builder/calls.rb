module QSexp
  module Call
    def initialize *o
      super
      on_parented do |p|
        if args[2].string == "each"
          z=p.parent
          def z.build_str ident = 0
            args[0].args[0].build_str ident
          end
        end
      end
    end
    
    def build_str ident = 0
      if args[2].string == "each"
        "\n#{" "*ident}foreach (#{parent.args[1].build_str.gsub(";\n",'')} #{parent.parent.args[1].parameters.untyped_parameters[0].build_str} in #{args[0].build_str})"+
        " {\n#{parent.parent.args[1].body_stmt.build_str(ident+2)}#{" "*ident}}"
      else
        super
      end
    end
  end

  module FCall
    def build_str ident=0
      super
    end
  end

  module VCall
    def build_str ident=0
      super
    end
  end

  module Command

  end
end
