# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'seadragon/version'

Gem::Specification.new do |spec|
  spec.name          = "seadragon"
  spec.version       = Seadragon::VERSION
  spec.authors       = ["Eddie Johnston"]
  spec.email         = ["eddie@beanstalk.ie"]

  spec.summary       = %q{The Seadragon Gem provides everything you need to create and host your own Deep Zoom Images using the OpenSeadragon image viewer. It provides methods for generating descriptor files and tiles from an image and comes bundled with the required OpenSeadragon Javascript and assets for displaying viewers.}
  spec.homepage      = "https://eddiej.github.io/seadragon"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.8"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec"
  spec.add_development_dependency "rails" ## for testing ::Rails::Engine
  spec.add_development_dependency "rspec-rails" 
  spec.add_development_dependency "guard"
  spec.add_development_dependency "guard-rspec"
  
  spec.add_dependency "rmagick"
  spec.add_development_dependency "coveralls"
end
