#
# Be sure to run `pod lib lint LukaSDK.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'LukaBluesnapSDK'
  s.version          = '0.0.2'
  s.summary          = 'Payments SDK'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
  Luka SDK for payments
                       DESC

  s.homepage         = 'https://github.com/josem0796/LukaBluesnap3DS'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'josemoran' => 'jmoran@lukapay.io' }
  s.source           = { :git => 'https://github.com/josem0796/LukaBluesnap3DS.git', :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'

  s.ios.deployment_target = '12.1'

  s.source_files = 'Classes/**/*'
  
  s.swift_version = '5'
  
#  s.pod_target_xcconfig = { 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'arm64' }
#  s.user_target_xcconfig = { 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'arm64' }
  
  # s.resource_bundles = {
  #   'LukaSDK' => ['LukaSDK/Assets/*.png']
  # }

  # s.public_header_files = 'Pod/Classes/**/*.h'
  # s.frameworks = 'UIKit', 'MapKit'
  # s.dependency 'AFNetworking', '~> 2.3'
  
  s.dependency 'RxSwift', '~> 6.2.0'
  s.dependency 'Alamofire', '~> 5.4'
  s.dependency 'BluesnapSDK', '~> 1.3.8'
  s.dependency 'RxRelay', '~> 0.1.2'
  
end
