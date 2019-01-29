namespace module Q
  namespace module Plugin
    class Loader < Object
      generic_types :T

      attr_reader path:string

      @type = :Type
      
      @gmodule = :Module

      delegate;def load_cb(gmodule:Module) :Type end

      def self.new(name:string)
        assert(Module.supported())
        @_path = Module.build_path(Environment.get_variable("PWD"), name);
      end

      def load() :bool
        printf "Loading plugin with path: '%s'\n", path

        @@gmodule = Module.open(path, ModuleFlags::BIND_LAZY);
        if (@@gmodule == nil)
          return false
        end

        printf "Loaded module: '%s'\n", @@gmodule.name();

        function = :'void*';
        @@gmodule.symbol("register_plugin", :out.function);
        loader = :load_cb.unowned
        loader = :load_cb > function;

        @type = loader(@@gmodule);
        printf "Plugin type: %s\n\n", @type.name();
        return true;
      end

      def make_object() :T
        return `Object.new(type)`
      end
    end
  end
end

Q.reqifdef Q_TEST, "~/tp.q"

`#if Q_TEST`
def main()
  loader = Q::Plugin::Loader[:Test::TestPlugin].new("myplugin");
  loader.load();

  plugin = :Test::TestPlugin
  plugin = loader.make_object();
  puts `plugin is Object`
  puts plugin == nil
  plugin.hello();
end
`#endif`