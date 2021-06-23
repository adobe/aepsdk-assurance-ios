# AEPAssurance Public APIs

This document contains usage information for the public functions and classes in `AEPAssurance`.

---

## extensionVersion

Returns the current version of the AEP Assurance extension.

##### Swift

**Signature**
```swift
static var extensionVersion: String
```

**Example Usage**
```swift
let assuranceVersion = Assurance.extensionVersion
```

##### Objective-C

**Signature**
```objc
+ (nonnull NSString*) extensionVersion;
```

**Example Usage**
```objc
NSString *assuranceVersion = AEPMobileAssurance.extensionVersion;
```

---

## startSession

Call the startSession API with a assurance session deeplink URL to connect to a session. When called, SDK displays a PIN authentication overlay to begin a session connection.


##### Swift

**Signature**
```swift
static func startSession(url: URL?)
```

**Example Usage**
```swift
func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
    Assurance.startSession(url: url)
    return true
}
```

For SceneDelegate based applications

```swift
func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
    if let deepLinkURL = connectionOptions.urlContexts.first?.url {
        Assurance.startSession(url: deepLinkURL)
    }
}

func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
    // This method is called when the app in background is opened with a deep link.
    // https://developer.apple.com/documentation/uikit/uiscenedelegate/3238059-scene
    if let deepLinkURL = URLContexts.first?.url {
        Assurance.startSession(url: deepLinkURL)
    }
}
```

##### Objective-C

**Signature**
```objc
+ (void) startSessionWithUrl: (NSURL* _Nonnull) url;
```

**Example Usage**
```objc
- (BOOL)application:(UIApplication *)app openURL:(nonnull NSURL *)url options:(nonnull NSDictionary<UIApplicationOpenURLOptionsKey,id> *)options {
    [AEPMobileAssurance startSessionWithUrl:url];
    return true;
}
```

For SceneDelegate based applications

```objc
- (void)scene:(UIScene *)scene willConnectToSession:(UISceneSession *)session options:(UISceneConnectionOptions *)connectionOptions {
    NSURL *deepLinkURL = connectionOptions.URLContexts.allObjects.firstObject.URL;
    [AEPMobileAssurance startSessionWithUrl:deepLinkURL];
}

- (void)scene:(UIScene *)scene openURLContexts:(NSSet<UIOpenURLContext *> *)URLContexts {
    [AEPMobileAssurance startSessionWithUrl:URLContexts.allObjects.firstObject.URL];
}
```
