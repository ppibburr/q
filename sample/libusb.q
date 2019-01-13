require "Q/usb"

def main()
  puts "USB Device List\n---------------"

  Q::USB.devices() do |dev|
    printf "\nBus number:   %04x", dev.get_bus_number();
    printf "\n  Address:    %04x", dev.get_device_address();

    desc = LibUSB::DeviceDescriptor(dev);
    printf "\n  Vendor ID:  %04x",   desc.idVendor;
    printf "\n  Product ID: %04x\n", desc.idProduct;
  end
end

