Q::package(:"libusb-1.0")
      
namespace module Q
  class USB
    delegate; def device_iter(d: :LibUSB::Device?); end
  
    def self.devices(cb:device_iter)
      context  = :LibUSB::Context
      dev_list = :'LibUSB.Device?[]'
      
      LibUSB::Context.init(:out.context)  

      nd = context.get_device_list(:out.dev_list) - 1

      nd.times do |i|
        cb(dev_list[i])
      end
  
      return dev_list
    end
  end
end
