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
  pod 'AEPAnalytics'
  pod 'AEPCore'
  pod 'AEPEdge'
  pod 'AEPEdgeConsent', :git => 'https://github.com/adobe/aepsdk-edgeconsent-ios.git', :branch => 'staging'
  pod 'AEPEdgeIdentity'
  pod 'AEPIdentity'
  pod 'AEPLifecycle'
  pod 'AEPMessaging', :git => 'https://github.com/adobe/aepsdk-messaging-ios.git', :branch => 'main'
  pod 'AEPPlaces', :git => 'https://github.com/adobe/aepsdk-places-ios.git', :branch => 'staging'
  pod 'AEPServices'
  pod 'AEPSignal'
  pod 'AEPTarget', :git => 'https://github.com/adobe/aepsdk-target-ios.git', :branch => 'staging'
  pod 'AEPUserProfile', :git => 'https://github.com/adobe/aepsdk-userprofile-ios.git', :branch => 'staging'
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

target 'TestApptvOS' do
  pod 'AEPAnalytics'
  pod 'AEPCore'
  pod 'AEPEdge'
  pod 'AEPEdgeConsent', :git => 'https://github.com/adobe/aepsdk-edgeconsent-ios.git', :branch => 'staging'
  pod 'AEPEdgeIdentity'
  pod 'AEPIdentity'
  pod 'AEPLifecycle'
  pod 'AEPMessaging', :git => 'https://github.com/adobe/aepsdk-messaging-ios.git', :branch => 'main'
  pod 'AEPPlaces', :git => 'https://github.com/adobe/aepsdk-places-ios.git', :branch => 'staging'
  pod 'AEPServices'
  pod 'AEPSignal'
#  pod 'AEPTarget', :git => 'https://github.com/adobe/aepsdk-target-ios.git', :branch => 'staging'
  pod 'AEPUserProfile', :git => 'https://github.com/adobe/aepsdk-userprofile-ios.git', :branch => 'staging'
end

post_install do |pi|
  pi.pods_project.targets.each do |t|
    t.build_configurations.each do |bc|
        bc.build_settings['TVOS_DEPLOYMENT_TARGET'] = '12.0'
        bc.build_settings['SUPPORTED_PLATFORMS'] = 'iphoneos iphonesimulator appletvos appletvsimulator'
        bc.build_settings['TARGETED_DEVICE_FAMILY'] = "1,2,3"
    end
  end
end
