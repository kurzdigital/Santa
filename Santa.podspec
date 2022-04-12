Pod::Spec.new do |s|
  s.name             = 'Santa'
  s.version          = '0.7.0'
  s.summary          = 'A resource based network communication lib'

  s.description      = <<-DESC
  Define your backend resources once and reuse them wherever you like. All the network related code
  is handled in a single place and can be easily monitored. Benefit from a clear and readable network communication
  api.
                       DESC

  s.homepage         = 'https://github.com/kurzdigital/Santa'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Christian Braun' => 'christian.braun@kurzdigital.com' }
  s.source           = { :git => 'https://github.com/kurzdigital/Santa.git', :tag => s.version.to_s }

  s.swift_version = "5.0"
  s.ios.deployment_target = '12.0'
  s.source_files = 'Sources/Santa/**/*.swift'
  s.frameworks = 'UIKit'
end
