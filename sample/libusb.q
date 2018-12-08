require 'Q'
require "Q/usb"

def main()
  print("\n USB Device List\n---------------\n");
  # initialize LibUSB and get the device list
  Q::USB.devices(proc do |dev|
    stdout.printf("\n Bus number : %04x", dev.get_bus_number());
    stdout.printf("\n Address : %04x", dev.get_device_address());

    desc = LibUSB::DeviceDescriptor(dev);
    stdout.printf("\n Vendor ID : %04x",  desc.idVendor);
    stdout.printf("\n Product ID : %04x", desc.idProduct);
  end)

  stdout.printf("\n")
end
__END__
# declare unowned value of type
name = :TYPE.unowned

# declare var type
name = literal|method_call|variable

# cast to type
# assign
a = :type << literal|method_call|variable
# param
foo(:out << literal|method_call|variable)

# owned from unowned
a = :owned << literal|method_call|variable

# out and ref
foo(:out << literal|method_call|variable, ref: << literal|method_call|variable)

# Arrays
a = :TYPE[]
a = :TYPE[len]
a = :TYPE[array, of, literals]
a = foo_returns_ary() # translates to `var`

a.each do |i|
  # ...
end

a[idx]
a[idx] = literal|method_call|variable

# Strings
str  = "..."
str2 = "#{str}"
str3 = str2[1..2]
str4 = :string
str4 = :string << bytes

# loops
while q != nil # i < max # etc
  q = foo_get_q()
  # i += 1
end

(0..max).each do |i|
  # ...
end

n.times do |i|
  # 
end

5.times do |i|
  #
end

for i in ary
  # ...
end

:TYPE.in(a) do |v|

end

# generics
# class
class F
  generics :T,:U
  def foo(t:T)
    generics :T
  end
end

F[:int].new(1)

