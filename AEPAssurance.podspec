Pod::Spec.new do |s|
  s.name             = "AEPAssurance"
  s.version          = "5.0.1"

  s.summary          = "AEPAssurance SDK for Adobe Experience Platform Mobile SDK. Written and maintained by Adobe."

  s.description      = <<-DESC
                       AEPAssurance extension enables capabilities for Project Griffon..
                       DESC

  s.homepage         = "https://github.com/adobe/aepsdk-assurance-ios.git"
  s.license          = { :type => "Apache License, Version 2.0", :file => "LICENSE" }
  s.author           = "Adobe Experience Platform SDK Team"
  s.source           = { :git => "https://github.com/adobe/aepsdk-assurance-ios.git", :tag => s.version.to_s }
  s.ios.deployment_target = '12.0'
  s.swift_version = '5.1'

  s.pod_target_xcconfig = { 'BUILD_LIBRARY_FOR_DISTRIBUTION' => 'YES' }
  s.dependency 'AEPCore', '>= 5.0.0', '< 6.0.0'
  s.dependency 'AEPServices', '>= 5.0.0', '< 6.0.0'


  s.source_files = 'AEPAssurance/Source/**/*.swift'
end
