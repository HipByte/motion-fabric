# -*- encoding: utf-8 -*-

Gem::Specification.new do |spec|
  spec.name        = 'motion-fabric'
  spec.version     = '1.0.2'
  spec.description = 'Fabric in your RubyMotion applications.'
  spec.summary     = 'motion-fabric allows you to easily integrate Fabric 
                      in your RubyMotion applications.'
  spec.author      = 'HipByte'
  spec.email       = 'info@hipbyte.com'
  spec.homepage    = 'http://www.rubymotion.com'
  spec.license     = 'Proprietary'
  spec.files       = Dir.glob('lib/**/*.rb')

  spec.add_runtime_dependency 'motion-cocoapods', '~> 1.9.1'
end
