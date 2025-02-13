# Adobe Experience Platform - Assurance extension for iOS

[![Cocoapods](https://img.shields.io/github/v/release/adobe/aepsdk-assurance-ios?label=Cocoapods&logo=apple&logoColor=white&color=orange&sort=semver)](https://cocoapods.org/pods/AEPAssurance)
[![SPM](https://img.shields.io/github/v/release/adobe/aepsdk-assurance-ios?label=SPM&logo=apple&logoColor=white&color=orange&sort=semver)](https://github.com/adobe/aepsdk-assurance-ios/releases)
[![CircleCI](https://img.shields.io/circleci/project/github/adobe/aepsdk-assurance-ios/main.svg?label=Build&logo=circleci)](https://circleci.com/gh/adobe/workflows/aepsdk-assurance-ios)
[![Code Coverage](https://img.shields.io/codecov/c/github/adobe/aepsdk-assurance-ios/main.svg?label=Coverage&logo=codecov)](https://codecov.io/gh/adobe/aepsdk-assurance-ios/branch/main)

## About this project

Adobe Experience Platform Assurance is a product from Adobe Experience Cloud to help you inspect, proof, simulate, and validate how you collect data or serve experiences in your mobile app. For more information on what Assurance can do for you, see [here](https://experienceleague.adobe.com/en/docs/experience-platform/assurance/home#what-can-assurance-do-for-you). To integrate Assurance in your app, refer to the [documentation](https://developer.adobe.com/client-sdks/home/base/assurance/).

## Requirements
- Xcode 15.0 or newer
- Swift 5.1 or newer

## Installation

### Binaries

To generate an `AEPAssurance.xcframework`, run the following command:

```ruby
$ make archive
```

This generates the xcframework under the `build` folder. Drag and drop all the `.xcframeworks` to your app target in Xcode.

### [CocoaPods](https://guides.cocoapods.org/using/using-cocoapods.html)

```ruby
# Podfile
use_frameworks!

target 'YOUR_TARGET_NAME' do
    pod 'AEPAssurance', '~> 5.0.0'
end
```

Replace `YOUR_TARGET_NAME` and then, in the `Podfile` directory, type:

```ruby
$ pod install
```

### [Swift Package Manager](https://github.com/apple/swift-package-manager)

To add the AEPAssurance Package to your application, from the Xcode menu select:

`File > Swift Packages > Add Package Dependency...`

Enter the URL for the AEPAssurance package repository: `https://github.com/adobe/aepsdk-assurance-ios.git`.

When prompted, input a specific version or a range of versions for Version rule.

Alternatively, if your project has a `Package.swift` file, you can add AEPAssurance directly to your dependencies:

```
dependencies: [
    .package(url: "https://github.com/adobe/aepsdk-assurance-ios.git", .upToNextMajor(from: "5.0.0"))
],
targets: [
    .target(name: "YourTarget",
            dependencies: ["AEPAssurance"],
            path: "your/path")
]
```

## TestApps
Two sample apps are provided (one each for Swift and Objective-c) which demonstrate setting up and getting started with Assurance extension. Their targets are in `AEPAssurance.xcodeproj`, runnable in `AEPAssurance.xcworkspace`. Sample app source code can be found in the `TestApp` and `TestAppObjC` directories.

## Development

The first time you clone or download the project, you should run the following from the root directory to setup the environment:

~~~
make pod-install
~~~

Subsequently, you can make sure your environment is updated by running the following:

~~~
make pod-update
~~~

#### Open the Xcode workspace
Open the workspace in Xcode by running the following command from the root directory of the repository:

~~~
make open
~~~

#### Command line integration

You can run all the test suites from command line:

~~~
make test
~~~

## Related Projects
| Project                                                      | Description                                                  |
| ------------------------------------------------------------ | ------------------------------------------------------------ |
| [AEPCore Extensions](https://github.com/adobe/aepsdk-core-ios) | The AEPCore and AEPServices represent the foundation of the Adobe Experience Platform SDK. |
| [AEP SDK Sample App for iOS](https://github.com/adobe/aepsdk-sample-app-ios) | Contains iOS sample apps for the AEP SDK. Apps are provided for both Objective-C and Swift implementations. |


## Documentation
Additional documentation for configuration and SDK usage can be found under the [Documentation](Documentation/README.md) directory.

## Contributing
Contributions are welcomed! Read the [Contributing Guide](./.github/CONTRIBUTING.md) for more information.
We look forward to working with you!

## Licensing
This project is licensed under the Apache V2 License. See [LICENSE](LICENSE) for more information.
