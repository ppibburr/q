module QSexp
  module Block
    include Body
    attr_accessor :delegate_type
    attr_reader :parameters, :body_stmt
    def initialize *o
      super
      @body_stmt = args[1]
      @parameters = args[0].args[0] if args[0]
      @parameters.untyped_parameters.map do |prm|
        n = prm.name
        scope.lvars[n] = :unknown
      end if parameters and parameters.untyped_parameters
    end
    def build_str ident=0
      q = !!parameters
      if q
        q = "(#{parameters.build_str})"
      else
        q = "()"
      end
      "#{q} => {\n#{" "*(ident+2)}"+
      super(ident)+
      "\n#{" "*ident}}"
    end
  end
end
