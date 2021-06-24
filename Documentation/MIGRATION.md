# Migration from AEPAssurance 1.x to AEPAssurance 3.x

## Who should migrate to AEPAssurance 3.x

---

If you are in the process of migration or already migrated to AEPCore from ACPCore then you must use AEPAssurance 3.x.x in your application. For more information see [Migrate to Swift SDK](https://aep-sdks.gitbook.io/docs/resources/migrate-to-swift).

The following table shows the SDK Core's compatibility with AEPAssurance:

| SDK Core | Assurance Version | Pod Installation | Manual Install |
| ----------- | -------- | ---------- | ------- |
| ACPCore | AEPAssurance 1.x | pod 'AEPAssurance', '~> 1.0' | [Available Here](https://github.com/Adobe-Marketing-Cloud/acp-sdks/tree/master/iOS/AEPAssurance)|
| AEPCore | AEPAssurance 3.x | pod 'AEPAssurance', '~> 3.0' | [Follow this command](../#binaries) |

---

## Primary class name

---

The class name containing public APIs is different depending on which SDK and language combination being used.

| SDK Version | Language | Class Name | Example |
| ----------- | -------- | ---------- | ------- |
| AEPAssurance 1.x | Objective-C | `AEPAssurance` | `[AEPAssurance startSession:url];`|
| AEPAssurance 1.x | Swift | `AEPAssurance` | `AEPAssurance.startSession(url)`|
| AEPAssurance 3.x | Objective-C | `AEPMobileAssurance` | `[AEPMobileAssurance startSessionWithUrl:url];` |
| AEPAssurance 3.x | Swift | `Assurance` | `Assurance.startSession(url)` |

## Public APIs

---

### extensionVersion

**AEPAssurance 1.x (Objective-C)**

```objc
+ (nonnull NSString*) extensionVersion;
```

**AEPAssurance 3.x  (Objective-C)**

```objc
+ (nonnull NSString*) extensionVersion;
```

**AEPAssurance 3.x (Swift)**

```swift
static var extensionVersion: String
```

---

### registerExtension

**AEPAssurance 1.x (Objective-C)**

```objc
+ (bool) registerExtension;
```

**AEPAssurance 3.x  (Objective-C)**

Not Available. Please see the [migration steps documentation (Objective C)](MIGRATIONObjC.md) to learn how to register AEPAssurance with AEPCore.

**AEPAssurance 3.x (Swift)**

Not Available. Please see the [migration steps documentation (Swift)](MIGRATIONSWIFT.md) to learn how to register AEPAssurance with AEPCore.

---

### startSession

**AEPAssurance 1.x (Objective-C)**

```objc
+ (void) startSession: (NSURL* _Nonnull) url;
```

**AEPAssurance 3.x  (Objective-C)**

```objc
+ (void) startSessionWithUrl:(NSURL* _Nonnull) url;
```

**AEPAssurance 3.x (Swift)**

```swift
static func startSession(url: URL?)
```



## Migration Steps

Click a link below for step by step migration guide to AEPAssurance 3.x.

- [Migration steps for Swift Application](MIGRATIONSWIFT.md)
- [Migration steps for ObjectiveC Application](MIGRATIONObjC.md)
