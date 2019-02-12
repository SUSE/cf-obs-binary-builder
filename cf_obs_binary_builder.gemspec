lib = File.expand_path('../lib/', __FILE__)
$:.unshift lib unless $:.include?(lib)
require 'cf_obs_binary_builder/version'

Gem::Specification.new do |s|
  s.name        = 'cf_obs_binary_builder'
  s.version     = '0.0.0'
  s.date        = '2018-05-07'
  s.summary     = "CF OBS binary builder"
  s.description = "A gem to create packages on Open Build Service for CloudFoundry buildpack binary dependencies"
  s.authors     = ["Dimitris Karakasilis"]
  s.email       = 'DKarakasilis@suse.com'
  s.files       = Dir.glob("{bin,lib}/**/*")
  s.require_path     = 'lib'
  s.executables << 'cf_obs_binary_builder'
  s.homepage    = 'http://rubygems.org/gems/cf_obs_binary_builder'
  s.license       = 'MIT'

  s.add_runtime_dependency 'tetra', '>= 2.0.5'
  s.add_runtime_dependency 'nokogiri'

  %w(pry pry-nav rspec).each { |gem| s.add_development_dependency gem }
end
