namespace module Q
  class USB
    delegate; def device_iter(d: :LibUSB::Device?); end
  
    macro; def devices(cb)
      Q::package(:"libusb-1.0")
      # declare objects
      context = :LibUSB::Context;
      LibUSB::Context.init(:out.context)  
      devices = :'LibUSB.Device?[]';
      nd = context.get_device_list(:out.devices) - 1
      if $M > 0
        c = :'Q.USB.device_iter'
        `#{c} = #{cb}`

        nd.times do |i|
          c(devices[i])
        end
      end
      return devices
    end
  end
end
