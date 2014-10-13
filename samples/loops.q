def main()
  print("=== array.each\n")
  a = :int[[0,1,2,3]]
  a.each(:int) do |q|
    print("%d\n", q)
  end
  
  print("=== for\n")
  for i in 0..a.length-1
    print("%d\n", i)
  end
  
  print("=== while\n")  
  z = 0
  while z < a.length
    print("%d\n", a[z])
    z += 1
  end 
  
  print("=== while with break\n")  
  z = 0
  while z < a.length
    if z == 2
      break
    end
    
    print("%d\n", a[z])
    z += 1
  end   
end
