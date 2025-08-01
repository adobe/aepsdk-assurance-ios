/*
 Copyright 2025 Adobe. All rights reserved.
 This file is licensed to you under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License. You may obtain a copy
 of the License at http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing, software distributed under
 the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR REPRESENTATIONS
 OF ANY KIND, either express or implied. See the License for the specific language
 governing permissions and limitations under the License.
 */

#if os(iOS)
import AEPAssurance
//import AEPPlaces
import AEPUserProfile
import AEPTarget
import AEPMessaging
#endif
import AEPCore
import AEPEdge
import AEPEdgeConsent
import AEPEdgeIdentity
import AEPEdgeBridge
import AEPIdentity
import AEPLifecycle
import AEPSignal
import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.        
        MobileCore.track(state: "Before SDK Init", data: nil)
        MobileCore.setLogLevel(.trace)
        
        var extensions: [NSObject.Type] = [AEPIdentity.Identity.self,
                          Lifecycle.self,
                          Edge.self,
                          //Consent.self,
                          EdgeBridge.self,
                          AEPEdgeIdentity.Identity.self
        ]
        
        #if os(iOS)
        extensions.append(Assurance.self)
        #endif
        
        let appState = application.applicationState
        MobileCore.registerExtensions(extensions, {
            // NOTE: - The app id is hardcoded in order to support e2e automated testing
            MobileCore.configureWith(appId: "YOUR_APP_ID")
            if appState != .background {
                MobileCore.lifecycleStart(additionalContextData: nil)
            }
        })

        return true
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
        #if os(iOS)
        Assurance.startSession(url: url)
        #endif
        return true
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        MobileCore.lifecyclePause()
    }
} 
