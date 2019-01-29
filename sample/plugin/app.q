require "Q/plugin/loader"
require "./plugin-interface"

namespace module Test
  def self.main()
    loader = Q::Plugin::Loader[:Test::PluginInterface].new("plugin");
    loader.load();

    plugin = loader.make_object();
  
    plugin.hello();
  end
end