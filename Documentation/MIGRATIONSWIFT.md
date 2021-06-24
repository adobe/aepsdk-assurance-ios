# AEPAssurance 3.x migration steps for Swift Apps

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

Make the following changes in your AppDelegate's `didFinishLaunchingWithOptions` method. If you are working with an Objective-C application, follow this [document](../MIGRATIONObjC.md).

```diff
- AEPAssurance.registerExtension()
- ACPCore.start {
-    ACPCore.configure(withAppId: "Your_AppID")
- }
+
+ import AEPAssurance
+ import AEPCore
+ ...
+
+  let extensions =  [
+                      Assurance.self     /// Also include the other installed extensions to this array
+                    ]
+  MobileCore.registerExtensions(extensions, {
+    MobileCore.configureWith(appId: "your_AppID")
+ })
+
```

## 3. Migrate startSession API

Make the following change to all occurrences of Assurance's startSession API call in your application. Here is an example :
```diff
func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {  
     guard let urlContexts = URLContexts.first else { return }
-    AEPAssurance.startSession(urlContexts.url)
+    Assurance.startSession(url: urlContexts.url)
}
```

## 4. Extension Version API
 The API to retrieve the version of Assurance extension should be changed as below.
 ```diff
- let version = AEPAssurance.extensionVersion()
+ let version = Assurance.extensionVersion
 ```
