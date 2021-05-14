# Uncomment the next line to define a global platform for your project
platform :ios, '10.0'

use_frameworks!
workspace 'AEPAssurance'
project 'AEPAssurance.xcodeproj'

target 'AEPAssurance' do
  pod 'AEPCore', :git => 'https://github.com/PravinPK/aepsdk-core-ios.git', :branch => 'assuranceSwift'
  pod 'AEPServices'
end

target 'UnitTests' do
  pod 'AEPCore', :git => 'https://github.com/PravinPK/aepsdk-core-ios.git', :branch => 'assuranceSwift'
  pod 'AEPServices'
end

target 'TestApp' do
  pod 'AEPCore', :git => 'https://github.com/PravinPK/aepsdk-core-ios.git', :branch => 'assuranceSwift'
  pod 'AEPServices'
  pod 'AEPLifecycle'
  pod 'AEPIdentity'
  pod 'AEPSignal'
  pod 'AEPRulesEngine'
  pod 'AEPEdge'
  pod 'AEPEdgeConsent'
  pod 'AEPEdgeIdentity'
  pod 'AEPUserProfile'
  pod 'AEPTarget'
  pod 'AEPAnalytics'
end
