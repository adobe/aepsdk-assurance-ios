# Uncomment the next line to define a global platform for your project
platform :ios, '12.0'

use_frameworks!
workspace 'AEPAssurance'
project 'AEPAssurance.xcodeproj'

pod 'SwiftLint', '0.52.0'

def core_pods
  pod 'AEPCore', :git => 'https://github.com/addb/aepsdk-core-ios.git', :branch => 'tvOSUI'
  pod 'AEPServices', :git => 'https://github.com/addb/aepsdk-core-ios.git', :branch => 'tvOSUI'
  pod 'AEPRulesEngine'
end

def shared_pods
  pod 'AEPAnalytics'
  pod 'AEPEdge'
  pod 'AEPEdgeConsent'
  pod 'AEPEdgeIdentity'
  pod 'AEPIdentity'
  pod 'AEPLifecycle'
  pod 'AEPSignal'
  pod 'AEPPlaces'
  pod 'AEPUserProfile'
end

target 'AEPAssurance' do
  core_pods
end

target 'UnitTests' do
  core_pods
end

target 'TestApp' do
  core_pods
  shared_pods
  pod 'AEPTarget'
  pod 'AEPMessaging'
end

target 'TestAppObjC' do
  core_pods
  shared_pods
  pod 'AEPTarget'
  pod 'AEPMessaging'

end

target 'TvTestApp' do
  platform :tvos, '12.0'
  core_pods
  pod 'AEPAnalytics'
  pod 'AEPEdge'
  pod 'AEPEdgeConsent'
  pod 'AEPEdgeIdentity'
  pod 'AEPIdentity'
  pod 'AEPLifecycle'
  pod 'AEPSignal'
  pod 'AEPEdgeMedia'
  pod 'AEPEdgeBridge'
end

post_install do |pi|
  pi.pods_project.targets.each do |t|
    t.build_configurations.each do |bc|
      bc.build_settings['TVOS_DEPLOYMENT_TARGET'] = '12.0'
    end
  end
end
