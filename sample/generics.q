class Foo < HashTable[:string?, :T]
  generic_types :T

  def self.new()
    base.full(str_hash, str_equal, nil, nil);
  end
end

foo = Foo[:int?].new()
foo["bar"] = 2
puts foo["bar"]
puts foo["quux"] == nil
