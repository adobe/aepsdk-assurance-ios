# TvTestApp - AEP Assurance Test App for tvOS

This is a tvOS test application for the AEP Assurance iOS SDK, based on the structure of the TestApp but adapted for Apple TV.

## Features

- **Assurance SDK Integration**: Full integration with AEP Assurance SDK for testing and debugging
- **Deep Link Support**: Supports Assurance session URLs through deep links
- **tvOS-Optimized UI**: Designed for tvOS with focus-based navigation and larger fonts
- **SDK Testing**: Includes cards for testing various AEP SDK features:
  - Assurance session management
  - Analytics tracking
  - User Profile management
  - Edge Consent
  - Places services
  - Large event handling

## Key Differences from TestApp

### UI/UX Adaptations for tvOS
- **Navigation**: Uses NavigationView for tvOS-style navigation
- **Button Styling**: Custom `TvButtonStyle` with larger buttons and better focus support
- **Font Sizes**: Increased font sizes for better readability on TV screens
- **Layout**: Optimized spacing and padding for TV viewing distance
- **Focus Management**: Buttons are designed to work with tvOS focus engine

### Feature Differences
- **Shake Gesture**: Removed shake gesture support (not available on tvOS)
- **Push Notifications**: Removed push notification support (not relevant for tvOS)
- **Analytics Events**: Updated with TV-specific event examples
- **User Profile**: Updated with TV-specific user attributes

### Technical Differences
- **Info.plist**: Configured for tvOS with `LSRequiresIPhoneOS` set to `false`
- **App Icons**: Uses tvOS-specific app icon and top shelf image structure
- **Launch Screen**: Designed for tvOS screen dimensions (1920x1080)
- **Entitlements**: Basic network client entitlement for tvOS

## File Structure

```
TvTestApp/
├── AppDelegate.swift              # Main app delegate
├── ContentView.swift              # Main SwiftUI view
├── SceneDelegate.swift            # Scene management
├── Info.plist                     # tvOS configuration
├── TvTestApp.entitlements         # App entitlements
├── Localizable.xcstrings          # Localization strings
├── sample.html                    # Sample HTML file for testing
├── sampleRules.json               # Sample rules for testing
├── README.md                      # This file
├── Assets.xcassets/               # App assets
│   ├── Contents.json
│   ├── AccentColor.colorset/
│   └── App Icon & Top Shelf Image.brandassets/
├── Base.lproj/
│   └── LaunchScreen.storyboard    # Launch screen
└── Preview Content/
    └── Preview Assets.xcassets/
```

## Usage

1. Add this target to your Xcode project
2. Configure the project settings for tvOS
3. Build and run on Apple TV Simulator or device
4. Use the Assurance URL field to connect to your Assurance session
5. Test various SDK features using the provided buttons

## Dependencies

This app requires the same AEP SDK dependencies as the TestApp:
- AEPCore
- AEPAssurance
- AEPAnalytics
- AEPEdge
- AEPEdgeConsent
- AEPEdgeIdentity
- AEPIdentity
- AEPLifecycle
- AEPPlaces
- AEPSignal
- AEPTarget
- AEPUserProfile
- AEPMessaging

## Notes

- The app uses the same configuration ID as the TestApp for consistency
- Deep links work the same way as on iOS
- The UI is optimized for the Apple TV remote and focus-based navigation
- All core SDK functionality is preserved and adapted for tvOS 