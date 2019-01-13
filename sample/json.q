require 'Q'
namespace module JSONSample
  macro; def get(j,n)
    
  end
  def self.main()
    begin
      parser = Json::Parser.new()
      parser.load_from_data(DATA, -1)

      root_object = parser.get_root().get_object()
      response    = root_object.get_object_member("response")
      results     = response.get_array_member("data")
      count       = results.get_length()

      puts "data has #{count} items:"

      results.get_elements().each do |e|
        o = e.get_object();
        puts "string data: #{o.get_string_member("string")}\ndouble data:#{o.get_double_member("double")}"
      end
    rescue Error => e
      puts "UH-OH :(\n#{e.domain} -- #{e.code}\n#{e.message}"
    end
  end
end

__END__

{
  "response" : {
    "data" : [{
      "string": "foo",
      "double": 3.33
    },{
      "string": "bar",
      "double": 1.11
    },{
      "string": "quux",
      "double": 7.77
    }]
  }
}
