namespace Q {







   public   delegate  void read_dir_cb(string f);



   public   delegate  void spawn_sync_cb(int status, string o, string e);





  public class File {
public static string? read(string f) {
      string? ss = null;
      FileUtils.get_contents(f, out ss);
      return (ss);

    }
  }


  public class Env {
public  virtual   string? get(string n) {
      return (GLib.Environment.get_variable(n));

    }

     public  virtual   bool contains(string n) {
      return (GLib.Environment.get_variable(n) != null);

    }

     public  virtual   void set(string n, string? v = null) {

      if (v == null) {
        GLib.Environment.unset_variable(n);

      }      else {
        GLib.Environment.set_variable(n, v, true);

      };

    }

     public  virtual   Q.Env.Iterator iterator() {
      return (new Q.Env.Iterator());

    }

     public  virtual   Q.Hash to_h() {
      var h = new Hash<string, string>();

      foreach (var v in GLib.Environment.list_variables()) {
        h[v] = get(v);

      };

      return (h);

    }

     public  virtual   string[] keys() {
      return (GLib.Environment.list_variables());

    }

     public  virtual   void to_string() {
      int _q14__Q__Iterable__join_pct_rav0_Q__Iterable__join_c; _q14__Q__Iterable__join_pct_rav0_Q__Iterable__join_c = 0;
        string? _q15__Q__Iterable__join_pct_rav2_Q__Iterable__join_x = ", ";
        string _q16__Q__Iterable__join_pct_rav6_Q__Iterable__join_s; _q16__Q__Iterable__join_pct_rav6_Q__Iterable__join_s = "";
      ;
        foreach (var _q17__Q__Iterable__join_pct_rav8_Q__Iterable__join_m in keys()) {;
      ;
          if ((_q14__Q__Iterable__join_pct_rav0_Q__Iterable__join_c) > 0) {;
            _q16__Q__Iterable__join_pct_rav6_Q__Iterable__join_s += _q15__Q__Iterable__join_pct_rav2_Q__Iterable__join_x;
      ;
          };
          _q16__Q__Iterable__join_pct_rav6_Q__Iterable__join_s += _q17__Q__Iterable__join_pct_rav8_Q__Iterable__join_m.to_string();
          _q14__Q__Iterable__join_pct_rav0_Q__Iterable__join_c += 1;
      ;
        };
      ;
        ;

    }

    public class Iterator {
public int id = 0;
      public string[]? list;

       public  virtual   bool next() {
        if ( this.list == null) {
           this.list = GLib.Environment.list_variables();
        };

        if (this.id < list.length) {
          return (true);
        }

        return (false);

      }

       public  virtual   string[] get() {
        var n = list[id];
        var res = GLib.Environment.get_variable(n);
        id += 1;
        string?[] a = null;
        a += n;
        a += res;
        return (a);

      }
    }
  }


  public class Hash<T, U> : GLib.Object {
private T[] _keys;
    private U?[] _values;

          construct {
      var _keys = new T[0];;
      var _values = new U[0];;

    }

     public  virtual   void set(T k, U? v = null) {
      var _q21__Q__Iterable__find_pct_rav0_Q__Iterable__find_o = -1;
        int _q22__Q__Iterable__find_pct_rav2_Q__Iterable__find_c; _q22__Q__Iterable__find_pct_rav2_Q__Iterable__find_c = 0;
      ;
        foreach (var _q23__Q__Iterable__find_pct_rav4_Q__Iterable__find_i in _keys) {;
      ;
          if (_q23__Q__Iterable__find_pct_rav4_Q__Iterable__find_i == k) {;
            _q21__Q__Iterable__find_pct_rav0_Q__Iterable__find_o = _q22__Q__Iterable__find_pct_rav2_Q__Iterable__find_c;
            break;
      ;
          };
          _q22__Q__Iterable__find_pct_rav2_Q__Iterable__find_c += 1;
      ;
        };
      ;
      var i = _q21__Q__Iterable__find_pct_rav0_Q__Iterable__find_o;;;;;

      if (i < 0) {
        i = _keys.length;
        this._keys += k;
        this._values += v;

      };
      this._keys[i] = k;
      this._values[i] = v;

    }

     public  virtual   U? get(T k) {
      var i = key_index(k);

      if (i >= 0) {
        return (_values[i]);

      };
      return (null);

    }

     public  virtual   int key_index(T k) {
      var i = -1;
      if (typeof(T) == typeof(string)) {
        var _q24__Q__Iterable__find_pct_rav0_Q__Iterable__find_o = -1;
  int _q25__Q__Iterable__find_pct_rav2_Q__Iterable__find_c; _q25__Q__Iterable__find_pct_rav2_Q__Iterable__find_c = 0;
;
  foreach (var _q26__Q__Iterable__find_pct_rav4_Q__Iterable__find_i in (string[])_keys) {;
;
    if (_q26__Q__Iterable__find_pct_rav4_Q__Iterable__find_i == (string)k) {;
      _q24__Q__Iterable__find_pct_rav0_Q__Iterable__find_o = _q25__Q__Iterable__find_pct_rav2_Q__Iterable__find_c;
      break;
;
    };
    _q25__Q__Iterable__find_pct_rav2_Q__Iterable__find_c += 1;
;
  };
;
  
i = _q24__Q__Iterable__find_pct_rav0_Q__Iterable__find_o;;;;;;;
      }

      if (typeof(T) == typeof(int)) {
        var _q27__Q__Iterable__find_pct_rav0_Q__Iterable__find_o = -1;
  int _q28__Q__Iterable__find_pct_rav2_Q__Iterable__find_c; _q28__Q__Iterable__find_pct_rav2_Q__Iterable__find_c = 0;
;
  foreach (var _q29__Q__Iterable__find_pct_rav4_Q__Iterable__find_i in (int[])_keys) {;
;
    if (_q29__Q__Iterable__find_pct_rav4_Q__Iterable__find_i == (int)k) {;
      _q27__Q__Iterable__find_pct_rav0_Q__Iterable__find_o = _q28__Q__Iterable__find_pct_rav2_Q__Iterable__find_c;
      break;
;
    };
    _q28__Q__Iterable__find_pct_rav2_Q__Iterable__find_c += 1;
;
  };
;
  
i = _q27__Q__Iterable__find_pct_rav0_Q__Iterable__find_o;;;;;;;;
      }

      if (typeof(T) == typeof(double?)) {
        var _q30__Q__Iterable__find_pct_rav0_Q__Iterable__find_o = -1;
  int _q31__Q__Iterable__find_pct_rav2_Q__Iterable__find_c; _q31__Q__Iterable__find_pct_rav2_Q__Iterable__find_c = 0;
;
  foreach (var _q32__Q__Iterable__find_pct_rav4_Q__Iterable__find_i in (double?[])_keys) {;
;
    if (_q32__Q__Iterable__find_pct_rav4_Q__Iterable__find_i == (double?)k) {;
      _q30__Q__Iterable__find_pct_rav0_Q__Iterable__find_o = _q31__Q__Iterable__find_pct_rav2_Q__Iterable__find_c;
      break;
;
    };
    _q31__Q__Iterable__find_pct_rav2_Q__Iterable__find_c += 1;
;
  };
;
  
i = _q30__Q__Iterable__find_pct_rav0_Q__Iterable__find_o;;;;;;;;;
      }

      return (i);

    }

     public  virtual   bool contains(T k) {
      var i = key_index(k);
      if (i >= 0) {
        return (true);
      }

      return (false);

    }

     public  virtual   T[] keys() {
      var a = new T[0];;

      foreach (T k in _keys) {
        a += k;

      };

      return (a);

    }

     public  virtual   bool has_key(T k) {
      return (contains(k));

    }

     public  virtual   U? delete(T k) {
      int i;
      i = key_index(k);

      if (i >= 0) {
        var g = get(k);
        var ka = new T[0];;
        var va = new U?[0];;

        for (int t = 0; t <= (_keys.length - 1); t++) {
          if (t != i) {
            ka += _keys[t];
          }

          if (t != i) {
            va += _values[t];
          }


        }

        this._keys = ka;
        this._values = va;
        return (g);

      };
      return (null);

    }

     public  virtual  delegate  void each_cb<T, U>(T k, U? v = null);

     public  virtual   void each_pair(each_cb cb) {
      int i; i = 0;

      foreach (var k in _keys) {
        cb(k, _values[i]);
        i += 1;

      };


    }
  }


}
