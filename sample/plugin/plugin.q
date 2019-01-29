require "plugin-interface.q"
class MyPlugin < Object
  include Test::PluginInterface
  def hello()
    print "Hello world!\n";
  end
end

def register_plugin(gmodule:Module) :Type
  #types are registered automatically
  return typeof(MyPlugin);
end