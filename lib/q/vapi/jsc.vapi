[CCode (lower_case_cprefix = "jsc_", cheader_filename = "jsc/jsc.h")]
namespace JSC {  
  [CCode (cname = "void", free_function = "g_object_unref")]
  public class Value : GLib.Object {
    public string to_string();
    public double to_number();
    public int32 to_int32();
    public bool to_boolean();
    public bool is_null();
    public bool is_undefined();
    public bool is_boolean();
    public bool is_object();
    public bool is_array();
    public bool is_constructor();
    
    public bool has_property(string n);
    
    public Context context;
    public Context get_context();
    
    [CCode (cname = "jsc_value_new_string")]
    public Value.string(Context c, string s);
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
    public delegate void* VariadicCallback(GLib.PtrArray a);
    [CCode (cname = "jsc_value_new_function_variadic")]
    public Value.function_variadic(Context c,
                                 string? name,
                                 [CCode (type = "GCallback")] VariadicCallback callback,
                                 GLib.DestroyNotify? destroy_notify,
                                 GLib.Type return_type); 
    
    [CCode (cname = "jsc_value_function_callv")]
    public Value function_callv([CCode(array_length_pos = 0.2)] Value[] args);
    [CCode (cname = "jsc_value_function_call", sentinel = "G_TYPE_NONE")]
    public Value function_call(GLib.Type t = typeof(void), ...);    
    
    [CCode (cname = "jsc_value_constructor_callv")]
    public Value constructor_callv([CCode(array_length_pos = 0.2)] Value[] args);
    [CCode (cname = "jsc_value_constructor_call", sentinel = "G_TYPE_NONE")]  
    public Value constructor_call(GLib.Type t = typeof(void), ...);         
    
    public void  object_set_property(string n, Value p); 
    public Value object_get_property(string n);
  }  
  
  [CCode (cname = "JSCContext", free_function = "g_object_unref")]
  public class Context : GLib.Object {
    public Value evaluate(string code, size_t len);
    public Value get_global_object();
    public Value get_value(string n);
    public void set_value(string n, Value v);
    [CCode (cname = "jsc_context_new")]
    public Context();
  }  
}
