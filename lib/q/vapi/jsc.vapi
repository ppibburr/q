[CCode (lower_case_cprefix = "jsc_", cheader_filename = "jsc/jsc.h")]
namespace JSC {  
  [CCode (cname = "JSCValue")]
  public class Value : GLib.Object {
    public string to_string();
    public double to_double();
    public int32 to_int32();
    public bool to_boolean();
    public bool is_null();
    public bool is_undefined();
    public bool is_boolean();
    public bool is_object();
    public bool is_string();
    public bool is_number();
    public bool is_array();
    public bool is_constructor();
    public bool is_function();    
    public bool has_property(string n);
    
    public Context context;
    public unowned Context get_context();
    
    [CCode (cname = "jsc_value_new_string")]
    public Value.string(Context c, string s);
    [CCode (cname = "jsc_value_new_array_from_strv")]
    public Value.array_from_strv(Context c, [CCode(array_length = false)] string[] s);    
    [CCode (cname = "jsc_value_new_array_from_garray")]
    public Value.array_from_garray(Context c, [CCode(array_length = false)] JSC.Value[] v);   
    [CCode (cname = "jsc_value_new_number")]
    public Value.number(Context c, double n);
    [CCode (cname = "jsc_value_new_boolean")]
    public Value.boolean(Context c, bool b);
    [CCode (cname = "jsc_value_new_null")]
    public Value.null(Context c);
    [CCode (cname = "jsc_value_new_undefined")]
    public Value.undefined(Context c); 
    [CCode (cname = "jsc_value_new_object")]
    public Value.object(Context c, void* ins = null, void* kls = null); 
        
    [CCode (type = "GCallback")]
    public delegate unowned void* VariadicCallback(GLib.PtrArray a);
    [CCode (cname = "jsc_value_new_function_variadic", destroy_notify_pos=0.4)]
    public Value.function_variadic([CCode (pos=0.0)] Context c,
                                 [CCode (pos=0.1)] string? name,
                                 [CCode (pos=0.4)] GLib.DestroyNotify? destroy_notify,
                                 [CCode (pos=0.5)] GLib.Type return_type,
                                 [CCode (type = "GCallback", pos=0.2)] VariadicCallback callback); 
    
    [CCode (cname = "jsc_value_function_callv")]
    public Value function_callv([CCode(array_length_pos = 0.2)] Value[] args);
    [CCode (cname = "jsc_value_function_call", sentinel = "G_TYPE_NONE")]
    public Value function_call(GLib.Type t = typeof(void), ...);    
    
    [CCode (cname = "jsc_value_constructor_callv")]
    public Value constructor_callv([CCode(array_length_pos = 0.2)] Value[] args);
    [CCode (cname = "jsc_value_constructor_call", sentinel = "G_TYPE_NONE")]  
    public Value constructor_call(GLib.Type t = typeof(void), ...);         
    
    public void  object_set_property(string n, Value p);

     
    public Value? object_get_property(string n);

    public Value? get(string n) { 
      return object_get_property(n);
    }
   
    public void set(string n, Value v) { object_set_property(n,v); }  

    [CCode (cname = "jsc_value_object_enumerate_properties", array_null_terminated = true)]
    public string[] object_enumerate_properties();
    
    public Value[] properties {
      owned get {
        var props = object_enumerate_properties();
        var a = new Value[props.length];
        for(var i=0; i<props.length;i++) {
          a[i] = this[props[i]];
        }
        return a;
      }
    }
  }  
  
  [CCode (cname = "JSCContext")]
  public class Context : GLib.Object {
    [CCode (cname="jsc_context_evaluate")]
    public Value evaluate(string code, size_t len);
    public Value eval(string code) {return evaluate(code, -1);}
    public Value get_global_object();
    public Value get_value(string n);
    public void set_value(string n, Value v);
    [CCode (cname = "jsc_context_new")]
    public Context();
  }  
}


