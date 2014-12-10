# encoding: utf-8
require 'rubygems'
require 'rubygems/package_task'

spec = load "./q.gemspec"

Gem::PackageTask.new(spec) do |pkg|
    pkg.need_tar = true
end

task :default => "build/#{spec.name}-#{spec.version}.gem" do
    puts "generated latest version"
end
