
 public    void main() {
  stdout.puts(("USB Device List\n---------------").to_string()); stdout.putc('\n');;
  Q.USB.devices((dev) => {
    stdout.printf("\nBus number:   %04x", dev.get_bus_number());;
    stdout.printf("\n  Address:    %04x", dev.get_device_address());;
    var desc = LibUSB.DeviceDescriptor(dev);
    stdout.printf("\n  Vendor ID:  %04x", desc.idVendor);;
    stdout.printf("\n  Product ID: %04x\n", desc.idProduct);;

  });

}
