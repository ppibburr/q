namespace Q {
  public class USB {
    public  virtual  delegate  void device_iter(LibUSB.Device? d = null);

    public static LibUSB.Device?[] devices(device_iter cb) {
      LibUSB.Context context;
      LibUSB.Context.init(out context);
      LibUSB.Device?[] dev_list;

      var nd = context.get_device_list(out dev_list) - 1;

      for (int i = 0; i <= nd; i++) {
        cb(dev_list[i]);
      }

      return (dev_list);
    }
  }
}
