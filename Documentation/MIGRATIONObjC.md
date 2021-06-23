# Migration from AEPAssurance 1.x to AEPAssurance 3.x (For Objective-C Apps)

## Who should migrate to AEPAssurance 3.x
- If you are in the process of migration or already migrated to AEPCore from ACPCore then you must use AEPAssurance 3.x.x in your application. For more information see [Migrate to Swift SDK](https://aep-sdks.gitbook.io/docs/resources/migrate-to-swift) documentation.


| SDK Core | Assurance Version | Pod Installation | Manual Install |
| ----------- | -------- | ---------- | ------- |
| ACPCore | AEPAssurance 1.x | pod 'AEPAssurance', '~> 1.0' | [Available Here](https://github.com/Adobe-Marketing-Cloud/acp-sdks/tree/master/iOS/AEPAssurance)|
| AEPCore | AEPAssurance 3.x | pod 'AEPAssurance', '~> 3.0' | [Follow this command]() |


## Primary class name

The class name containing public APIs is different depending on which SDK is being used.

| SDK Version | Language | Class Name | Example |
| ----------- | -------- | ---------- | ------- |
| AEPAssurance 1.x | Objective-C | `AEPAssurance` | `[AEPAssurance startSession:url];`|
| AEPAssurance 3.x | Objective-C | `AEPMobileAssurance` | `[AEPMobileAssurance startSessionWithUrl:url];` |

## Migration steps
##  1.a. Update Podfile
Open the `Podfile` of your application and make the following changes.

```diff
- pod 'ACPCore'
- pod `AEPAssurance`, '~> 1.0'

+ pod 'AEPCore'
+ pod 'AEPServices'
+ pod `AEPAssurance`, '~> 3.0'
```

Then run `pod install` and build the project, now the project will be using the latest AEPCore and AEPAssurance SDK.


##  1.b. Manual Install
Please ignore this section if you are using CocoaPods or Swift Package Manager to manage dependencies.
- Remove the existing `AEPAssurance.xcframework` from your project.
- Create and Install the latest `AEPAssurance.xcframework` by following [this command]().

## 2. Registration of Assurance Extension

The following changes should be made in your AppDelegate's `didFinishLaunchingWithOptions` method.

```diff
- [AEPAssurance registerExtension];
- [ACPCore start:^{
-       [ACPCore configureWithAppId:@"Your_AppID"];
-  }];
+
+ @import AEPAssurance;
+ @import AEPCore;
+ ...
+
+  NSArray* extensionsToRegister = @[AEPMobileAssurance.class];
+  [AEPMobileAssurance registerExtensions:extensionsToRegister completion:^{
+     [AEPMobileCore configureWithAppId: @"Your_AppID"];
+  }];
+
```

## 3. Migrate startSession API

Make the following change to all occurances of Assurance's startSession API call in your application. Here is an example
```diff
 - (void)scene:(UIScene *)scene openURLContexts:(NSSet<UIOpenURLContext *> *)URLContexts {
      NSURL *url = URLContexts.allObjects.firstObject.URL;
      // validate the url
-    [AEPAssurance startSession:url];
+    [AEPMobileAssurance startSessionWithUrl:url];
}
```

## 4. Extension Version API
 The API to retrieve the version of Assurance extension should be changed as below.
 ```diff
- NSString* version = [AEPAssurance extensionVersion];
+ NSString* version = AEPMobileAssurance.extensionVersion;
 ```
