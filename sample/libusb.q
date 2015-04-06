using LibUSB;

def main()
    # declare objects
    context = :Context;
    devices = :Device?[];

    # initialize LibUSB and get the device list
    Context.init( :out << context );
    context.get_device_list(:out << devices);

    print("\n USB Device List\n---------------\n");

    # iterate through the list
    i = 0
    while devices[i] != nil
        # we print all values in hexadecimal here
        dev = devices[i]
        stdout.printf("\n Bus number : %04x", dev.get_bus_number());
        stdout.printf("\n Address : %04x", dev.get_device_address());

        desc = DeviceDescriptor(dev);
        stdout.printf("\n Vendor ID : %04x",  desc.idVendor);
        stdout.printf("\n Product ID : %04x", desc.idProduct);

        stdout.printf("\n");
      i = i + 1
    end
end
