/*
 Copyright 2021 Adobe. All rights reserved.
 This file is licensed to you under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License. You may obtain a copy
 of the License at http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing, software distributed under
 the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR REPRESENTATIONS
 OF ANY KIND, either express or implied. See the License for the specific language
 governing permissions and limitations under the License.
 */

import AEPAnalytics
import AEPAssurance
import AEPCore
import AEPEdge
import AEPEdgeConsent
import AEPEdgeIdentity
import AEPIdentity
import AEPLifecycle
import AEPPlaces
import AEPSignal
import AEPTarget
import AEPUserProfile
import AEPMessaging
import AEPServices
import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    let notificationCenter = UNUserNotificationCenter.current()

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.        
        requestNotificationPermission()
        MobileCore.track(state: "Before SDK Init", data: nil)
        MobileCore.setLogLevel(.trace)

        // Set QuickConnect Environment
        ServiceProvider.shared.namedKeyValueService.set(collectionName: "com.adobe.assurance", key: "assurance.environment", value: "qa")
//        ServiceProvider.shared.namedKeyValueService.set(collectionName: "com.adobe.assurance", key: "assurance.environment", value: "stage")
//        ServiceProvider.shared.namedKeyValueService.set(collectionName: "com.adobe.assurance", key: "assurance.environment", value: "")
        let extensions = [AEPIdentity.Identity.self,
                          Lifecycle.self,
                          Signal.self,
                          Edge.self,
                          Consent.self,
                          Analytics.self,
                          AEPEdgeIdentity.Identity.self,
                          Target.self,
                          Consent.self,
                          UserProfile.self,
                          Assurance.self,
                          Places.self,
                          Messaging.self
        ]
        let appState = application.applicationState
        MobileCore.registerExtensions(extensions, {
            MobileCore.configureWith(appId: "")
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
        Assurance.startSession(url: url)
        return true
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        MobileCore.lifecyclePause()
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        MobileCore.setPushIdentifier(deviceToken)
    }
    
    private func requestNotificationPermission() {
        notificationCenter.delegate = self

        let options: UNAuthorizationOptions = [.alert, .sound, .badge]

        notificationCenter.requestAuthorization(options: options) {
            didAllow, _ in
            if !didAllow {
                print("User has declined notifications")
            }
        }
    }

}
