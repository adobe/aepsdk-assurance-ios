# Uncomment the next line to define a global platform for your project
platform :ios, '12.0'

use_frameworks!
workspace 'AEPAssurance'
project 'AEPAssurance.xcodeproj'

pod 'SwiftLint', '0.52.0'

target 'AEPAssurance' do
  pod 'AEPCore', :git => 'https://github.com/adobe/aepsdk-core-ios.git', :branch => 'dev-v5.0.0'
  pod 'AEPServices', :git => 'https://github.com/adobe/aepsdk-core-ios.git', :branch => 'dev-v5.0.0'
  pod 'AEPRulesEngine', :git => 'https://github.com/adobe/aepsdk-rulesengine-ios.git', :branch => 'dev-v5.0.0'
end

target 'UnitTests' do
  pod 'AEPCore', :git => 'https://github.com/adobe/aepsdk-core-ios.git', :branch => 'dev-v5.0.0'
  pod 'AEPServices', :git => 'https://github.com/adobe/aepsdk-core-ios.git', :branch => 'dev-v5.0.0'
  pod 'AEPRulesEngine', :git => 'https://github.com/adobe/aepsdk-rulesengine-ios.git', :branch => 'dev-v5.0.0'
end

target 'TestApp' do
  pod 'AEPCore'
  pod 'AEPServices'
  pod 'AEPLifecycle'
  pod 'AEPIdentity'
  pod 'AEPSignal'
  pod 'AEPEdge'
  pod 'AEPEdgeConsent'
  pod 'AEPEdgeIdentity'
  pod 'AEPUserProfile'
  pod 'AEPTarget'
  pod 'AEPAnalytics'
  pod 'AEPPlaces'
  pod 'AEPMessaging'
end

target 'TestAppObjC' do
  pod 'AEPCore'
  pod 'AEPServices'
  pod 'AEPLifecycle'
  pod 'AEPIdentity'
  pod 'AEPSignal'
  pod 'AEPEdge'
  pod 'AEPEdgeConsent'
  pod 'AEPEdgeIdentity'
  pod 'AEPUserProfile'
  pod 'AEPTarget'
  pod 'AEPAnalytics'
  pod 'AEPPlaces'
end
