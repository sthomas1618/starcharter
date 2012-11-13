# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "starcharter/version"

Gem::Specification.new do |s|
  s.name        = "starcharter"
  s.version     = Starcharter::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Stephen Thomas"]
  s.email       = ["sthomas1618@gmail.com"]
  s.homepage    = "https://github.com/sthomas1618/starcharter"
  s.date        = Date.today.to_s
  s.summary     = "Fork of Geocoder for mapping linear x-y coordinates."
  s.description = "Based on the popular Geocoder, this repurposes it has a simple gem for querying ones own custom data based on x-y coordinates."
  s.files       = `git ls-files`.split("\n") - %w[starcharter.gemspec Gemfile init.rb]
  s.require_paths = ["lib"]
end
