namespace module Q
  namespace module Plugin
    class Loader < Object
      DEFAULT_SYMBOL = "register_plugin"
    
      generic_types :T

      attr_reader path:string
      attr_reader register_symbol:string
      attr_reader gtype:Type
      attr_reader gmodule:Module

      delegate;def load_cb(gmodule:Module) :Type end

      def self.new(name:string, reg_sym: :string?)
        @_register_symbol = reg_sym == nil ? DEFAULT_SYMBOL : reg_sym
        assert(Module.supported())
        @_path = Module.build_path(Environment.get_variable("PWD"), name);
      end

      def load() :bool
        printf "Loading plugin with path: '%s'\n", path

        @_gmodule = Module.open(path, ModuleFlags::BIND_LAZY);
        if (@gmodule == nil)
          return false
        end

        printf "Loaded module: '%s'\n", @gmodule.name();

        function = :'void*';
        @@gmodule.symbol(register_symbol, :out.function);
        loader = :load_cb.unowned
        loader = :load_cb > function;

        @_gtype = loader(@gmodule);
        printf "Plugin type: %s\n\n", @gtype.name();
        return true;
      end

      def make_object() :T
        return Object @gtype
      end
    end
  end
end
