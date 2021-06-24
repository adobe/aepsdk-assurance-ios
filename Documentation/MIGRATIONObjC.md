# AEPAssurance 3.x migration steps for Objective-C Apps

##  1.a. Update Podfile

Open the `Podfile` of your application and make the following changes.

```diff
- pod 'ACPCore'
- pod `AEPAssurance`, '~> 1.0'

+ pod 'AEPCore'
+ pod `AEPAssurance`, '~> 3.0'
```

Then run `pod install` and build the project, now the project will be using the latest AEPCore and AEPAssurance SDK.

##  1.b. Manual Install
Please ignore this section if you are using CocoaPods or Swift Package Manager to manage dependencies.
- Remove the existing `AEPAssurance.xcframework` from your project.
- Create and Install the latest `AEPAssurance.xcframework` by following [this command](../#binaries).

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
+  [AEPMobileCore registerExtensions:extensionsToRegister completion:^{
+     [AEPMobileCore configureWithAppId: @"Your_AppID"];
+  }];
+
```

## 3. Migrate startSession API

Make the following change to all occurrences of Assurance's startSession API call in your application. Here is an example :
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
