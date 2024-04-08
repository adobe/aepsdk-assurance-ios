# Uncomment the next line to define a global platform for your project
platform :ios, '12.0'

use_frameworks!
workspace 'AEPAssurance'
project 'AEPAssurance.xcodeproj'

pod 'SwiftLint', '0.52.0'

target 'AEPAssurance' do
  pod 'AEPCore'
  pod 'AEPServices'
  pod 'AEPRulesEngine'
end

target 'UnitTests' do
  pod 'AEPCore'
  pod 'AEPServices'
  pod 'AEPRulesEngine'
end

target 'TestApp' do
  pod 'AEPCore'
  pod 'AEPServices'
  pod 'AEPLifecycle'
  pod 'AEPIdentity'
  pod 'AEPSignal'
  pod 'AEPEdge'
  pod 'AEPEdgeConsent', :git => 'https://github.com/adobe/aepsdk-edgeconsent-ios.git', :branch => 'staging'
  pod 'AEPEdgeIdentity'
  pod 'AEPUserProfile', :git => 'https://github.com/adobe/aepsdk-userprofile-ios.git', :branch => 'staging'
  pod 'AEPTarget', :git => 'https://github.com/adobe/aepsdk-target-ios.git', :branch => 'staging'
  pod 'AEPAnalytics'
  pod 'AEPPlaces', :git => 'https://github.com/adobe/aepsdk-places-ios.git', :branch => 'staging'
  pod 'AEPMessaging', :git => 'https://github.com/adobe/aepsdk-messaging-ios.git', :branch => 'staging'
end

target 'TestAppObjC' do
  pod 'AEPCore'
  pod 'AEPServices'
  pod 'AEPLifecycle'
  pod 'AEPIdentity'
  pod 'AEPSignal'
  pod 'AEPEdge'
  pod 'AEPEdgeConsent', :git => 'https://github.com/adobe/aepsdk-edgeconsent-ios.git', :branch => 'staging'
  pod 'AEPEdgeIdentity'
  pod 'AEPUserProfile', :git => 'https://github.com/adobe/aepsdk-userprofile-ios.git', :branch => 'staging'
  pod 'AEPTarget', :git => 'https://github.com/adobe/aepsdk-target-ios.git', :branch => 'staging'
  pod 'AEPAnalytics'
  pod 'AEPPlaces', :git => 'https://github.com/adobe/aepsdk-places-ios.git', :branch => 'staging'
end
