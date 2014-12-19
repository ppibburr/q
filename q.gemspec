$:.push File.expand_path("../lib", __FILE__)
require "q/version"

Q::SPEC = Gem::Specification.new do |s|
  s.version     = Q::VERSION

  gem = s
  gem.name = "q"
  gem.homepage = "http://github.com/ppibburr/q"
  gem.license = "MIT"
  gem.summary = %Q{Q - Ruby syntax for Vala}
  gem.description = %Q{Q - Ruby syntax for Vala}
  gem.email = "tulnor33@gmail.com"
  gem.authors = ["ppibburr"]

  s.files         = `git ls-files`.split("\n")
  
  s.files.reject! {|f| 
    f.include?("sample/")
  }
  
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
end
