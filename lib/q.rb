$: << File.expand_path(File.dirname(__FILE__))

require 'ripper'

require 'q/builder/base.rb'
require 'q/ripper/qsexp'
require 'q/builder/builder.rb'

module QSexp
  BUFFER = []
end

if __FILE__ == $0
QSexp.build(c="
  namespace N do
    @@z = :int[1,2,3,4]
    @@n = :int[]
    @@c = :int
    @@str = :string
    @@s2 = \"foo\"
    class N < Object
      @@s_fld = :int[4]
      @i_fld  = :int
      @i_f2 = 3
      @i_flt = 3.0 # Floats default to <flt>f, ie, 3.0f
      @i_dbl = 3.0.d # as `double`
      $c_fld  = 5.f  # as `flt`

      def foo(x:int[]):void
        @@ss_fld = [1,2,3,4]
        @i_fld = x
        lcl = 5
        
        x=int(5)
        la = :int[1,2,3]
        
        str_l = \"ed\"
        @@str = \"foo\"
        
        print(6)
      end
    end
  end

").write
pp Ripper.sexp(c)
puts QSexp::BUFFER.join
end
