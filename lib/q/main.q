namespace module Q
  macro :timeout, 'GLib.Timeout.add(%v1_Q__timeout, '
  macro :idle,    'GLib.Idle.add('
  
  @@main_loop = :MainLoop?

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
  
  macro :idle, 'GLib.Idle.add('
  macro :timeout, 'GLib.Timeout.add(%v1_Q__timeout, '
end
