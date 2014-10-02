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
    
    class N < Object
      @@s_fld = :int[4]
      @i_fld  = :int
      $c_fld  = 5.f
    
      def foo(x:int[]):void
        @@ss_fld = [1,2,3,4]
        @i_fld = x
      end
    end
  end
").write
pp Ripper.sexp(c)
puts QSexp::BUFFER.join
end
