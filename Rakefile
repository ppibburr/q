# encoding: utf-8
require 'rubygems'
require 'rubygems/package_task'

load "./q.gemspec"

Gem::PackageTask.new(Q::SPEC) do |pkg|
    pkg.need_tar = true
end

task :default => "build/#{Q::SPEC.name}-#{Q::SPEC.version}.gem" do
    puts "generated latest version"
end
