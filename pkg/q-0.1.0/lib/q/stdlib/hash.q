namespace module Q
  class Hash < HashTable[:string?, :T]
    generic_types :T

    def self.new()
      base.full(str_hash, str_equal, nil, nil);
    end
   
    property keys: :string[] do get do :owned; return get_keys_as_array() end end
  end
end

