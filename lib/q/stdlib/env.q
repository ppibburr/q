namespace module Q
  module Env
    include Q::Macros  
    macro; def get(n)
      GLib::Environment.get_variable(n)
    end

    macro; def contains(n)
      (GLib::Environment.get_variable(n) != nil)
    end

    macro; def set(n ,v)
      if v==nil
        GLib::Environment.unset_variable(n)
      else
        GLib::Environment.set_variable(n,v, true)
      end
    end

    macro; def keys()
      GLib::Environment.list_variables()
    end
    
    macro; def to_h()
      `var #{e} = #{Hash[:string?].new()}`
      keys = GLib.Environment.list_variables()
      keys.each do |k|
        `#{e}[#{k}] = #{Q::Env.get(k)}`
      end
      
      return e
    end
  end
  
  def self.env() :'GLib.HashTable<string?, string?>'
    e = Q::Env.to_h()
    return e
  end
end

