Q::package(:"jsc")
require "Q/stdlib/file"
namespace module Q
  class JSCValue
    delegate;def cb(a: :GLib::PtrArray) :JSC::Value; end    
    delegate;def cb_full(a: :GLib::PtrArray) :'void*'; end
    attr_reader value: :JSC::Value
    attr_reader context: :JSC::Context
    def set_func(n:string, cb: :cb) :Q::JSCValue
      fun = JSC::Value.new_function_variadic(@_value.get_context(), n, nil, typeof(JSC.Value), :cb_full > cb);
      @_value[n] = fun;
    
      return this;
    end
    
    def set_prop(n:string, v: :JSC::Value) :Q::JSCValue
      @value.object_set_property(n,v)
      return self
    end
    
    def self.new_build(c: :JSC::Context, s:string)
      @_context = c
      @_value   = c.eval(s)
    end 
  end
  
  class JS < Object
    def self.puts(a:PtrArray) :JSC::Value
      :JSC::Value s = :JSC::Value > a.index(0)
      puts s
      return s
    end
    def self.read(a:PtrArray) :JSC::Value
       :JSC::Value pth = :JSC::Value > a.index(0)
      return JSC::Value.new_string(pth.get_context(), Q.read(pth.to_string()))
    end
    def self.write(a:PtrArray) :JSC::Value
      :JSC::Value pth = :JSC::Value > a.index(0)
      :JSC::Value s   = :JSC::Value > a.index(1)
      Q.write(pth.to_string(),s.to_string())
      return s
    end
    def self.init(c:JSC::Context)
      qjs = JS c, bool: true, read: read, write: write, bar: 9, puts: puts
      go=c.get_global_object()
      go["QJs"] = qjs      
      qjs.ref() 
    end
    
    def self.mkobject(c: :JSC::Context, s:string) :JSC::Value
      return Q::JSCValue.new_build(c,"_q_tmp_mkobject = #{s}; _q_tmp_mkobject;").value
    end
    
    def self.jval2gval(v: :JSC::Value) :Value?
      return nil if v.is_null()
      
      g = :Value?
      
      g = v.to_string()  if v.is_string()
      g = v.to_boolean() if v.is_boolean()
      g = v.to_double()  if v.is_number()
      g = v if v.is_object()
      g = v if v.is_array()
      g = v if v.is_constructor()
      g = v if v.is_function()    
      
      return g
    end
    
    def self.gval2jval(context:JSC::Context, v:Value) :JSC::Value
      j = :JSC::Value?
      
      j = JSC::Value.new_string(context, :string > v) if v.type() == typeof(:string)
      j = JSC::Value.new_number(context, :double > (:int > v)) if v.type() == typeof(:int)
      j = JSC::Value.new_number(context, :double > v) if v.type() == typeof(:double)
      j = JSC::Value.new_boolean(context, :bool > v)  if v.type() == typeof(:bool)
      j = JSC::Value.new_array_from_strv(context, :'string[]' > v)      if v.type() == typeof(:string[])      
      j = JSC::Value.new_array_from_garray(context, :'JSC.Value[]' > v) if v.type() == typeof(:JSC::Value[])  
      j = :JSC::Value > v if v.type() == typeof(:JSC::Value)  
      
      return j
    end    
  end
  
  class JSPlugin < JSCValue
    class Call < Object
      delegate;def callback(va: :Value[]) :Value; end
      attr_reader cb:callback
      attr_reader context: :JSC::Context
      def call(a:PtrArray) :'void*'
        `Value[] va = new Value[a.len];`
        for i in 0..a.len-1
          :JSC::Value j = :JSC::Value > a.index(i) 
          va[i] = Q::JS.jval2gval(j)
        end
        :GLib.Value ret = cb(va)

        return :'void*' > Q::JS.gval2jval(context, ret)
      end
      def self.new(c: :JSC::Context, cb:callback)
        @_context = c
        @_cb = cb
      end
    end
    
    def set_func(n:string, cb: :Call::callback) :Q::JSPlugin
      c = Call.new(@value.get_context(), cb)
      c.ref()
      fun = JSC::Value.new_function_variadic(@value.get_context(), n, nil, typeof(:JSC::Value), c.call);
      @value[n] = fun;

      return this;
    end
    
    
    def self.new_build(c: :JSC::Context, s:string)
   
      base.build(c,s)
    end
    
    def set(s:string, v:Value)    
      @value[s] = Q::JS.gval2jval(@context, v)
    end
    
    def get(s:string) :Value?
      v = @value[s]
      g = Q::JS.jval2gval(v)    
      return g
    end
    
    def contains(s:string) :bool
      return `s in this.value.object_enumerate_properties()`
    end 
    
    def jval(n:string) :'JSC.Value?'
      return @value[n]
    end
    
    def str(n:string) :string
      return jval(n).to_string()
    end
    
    def alen(t:int, v: :Value[]) :bool
      return v.length == t
    end
    
    def types(t: :Type[], v: :Value[])
      for i in 0..(v.length-1)
        puts v[i].type()
        return false if t[i] != v[i].type()
      end
      
      return true
    end
  end
end
