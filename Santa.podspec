#
# Be sure to run `pod lib lint Santa.podspec' to ensure this is a
# valid spec before submitting.
#

Pod::Spec.new do |s|
  s.name             = 'Santa'
  s.version          = '0.1.0'
  s.summary          = 'A resource based network communication lib'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
  Define your backend resources once and reuse them wherever you like. All the network related code
  is handled in a single place and can be easily monitored. Benefit from a clear and readable network communication
  api.
                       DESC

  s.homepage         = 'https://github.com/Christian Braun/Santa'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Christian Braun' => 'christian.braun@kurzdigital.com' }
  s.source           = { :git => 'https://github.com/Christian Braun/Santa.git', :tag => s.version.to_s }

  s.ios.deployment_target = '8.0'

  s.source_files = 'Santa/Classes/**/*'
  
  # s.resource_bundles = {
  #   'Santa' => ['Santa/Assets/*.png']
  # }

  # s.public_header_files = 'Pod/Classes/**/*.h'
  # s.frameworks = 'UIKit', 'MapKit'
  # s.dependency 'AFNetworking', '~> 2.3'
end
