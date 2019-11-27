namespace module Q
  macro :every, 'GLib.Timeout.add(%v1_Q__every, '
  macro :idle,  'GLib.Idle.add('
  
  @@main_loop = :MainLoop?
  @@__prog_name = :string?
  
  def self.prog_name() :string
    return @@__prog_name if @@__prog_name != nil
    return GLib::Environment.get_prgname()
  end
  
  def self.set_prog_name(s:string)
    @@__prog_name = s
    GLib::Environment.set_prgname(s)
  end
  
  delegate; def main_cb(); end

  def self.main(cb: :main_cb?) :MainLoop
    if @@main_loop == nil
      @@main_loop = MainLoop.new()
      cb() if cb != nil
      @@main_loop.run()
    end

    return @@main_loop
  end

  def self.quit()
     @@main_loop.quit() if @@main_loop != nil
  end
  
  delegate;def idle_cb();end
  def self.idle_once(cb:idle_cb)
    GLib::Idle.add() do
      cb()
      next false
    end
  end
  
  def self.timeout(t:int, cb:idle_cb)
    Q.every(t) do
      cb()
      next false
    end
  end
end
