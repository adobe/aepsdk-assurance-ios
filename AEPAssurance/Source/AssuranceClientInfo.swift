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

import AEPServices
import CoreLocation
import Foundation

struct AssuranceClientInfo {

    /// Retrieves a `Dictionary` containing the client information required for the Assurance client event
    /// Client information includes
    /// 1. AppSetting Data  - Information from the info.plist
    /// 2. Device Information - Information like (Device Name, Device type, Battery level, OS Info, Location Auth status, etc.. )
    /// 3. Assurance extension's current verison
    ///
    /// - Returns- A `Dictionary` containing the above mentioned data
    static func getData() -> [String: AnyCodable] {
        return [AssuranceConstants.ClientInfoKeys.VERSION: AnyCodable.init(AssuranceConstants.EXTENSION_VERSION),
                AssuranceConstants.ClientInfoKeys.TYPE: "connect",
                AssuranceConstants.ClientInfoKeys.APP_SETTINGS: AnyCodable.init(readAppSettingData()),
                AssuranceConstants.ClientInfoKeys.DEVICE_INFO: AnyCodable.init(readDeviceInfo())]
    }

    // MARK: - Private helper methods
    /// - Returns: A `Dictionary` containing plist data
    private static func readAppSettingData() -> NSDictionary {
        var appSettingsInDictionary: NSDictionary = [:]
        if let path = Bundle.main.path(forResource: "Info", ofType: "plist") {
            appSettingsInDictionary = NSDictionary(contentsOfFile: path) ?? [:]
        }
        return appSettingsInDictionary
    }

    ///- Returns: A `Dictionary` representing the battery level of the device
    private static func readDeviceInfo() -> [String: Any] {
        let screenSize = ServiceProvider.shared.systemInfoService.getDisplayInformation()
        var deviceInfo: [String: Any] = [:]
        deviceInfo["Canonical platform name"] = "iOS"
        deviceInfo["Device name"] = UIDevice.current.name
        deviceInfo["Operating system"] = ("\(ServiceProvider.shared.systemInfoService.getOperatingSystemName()) \(ServiceProvider.shared.systemInfoService.getOperatingSystemVersion())")
        deviceInfo["Device type"] = getDeviceType()
        deviceInfo["Model"] = ServiceProvider.shared.systemInfoService.getDeviceModelNumber
        deviceInfo["Screen size"] = "\(screenSize.width)x\(screenSize.height)"
        deviceInfo["Location service enabled"] = Bool(CLLocationManager.locationServicesEnabled())
        deviceInfo["Location authorization status"] = getAuthStatusString(authStatus: CLLocationManager.authorizationStatus())
        deviceInfo["Low power mode enabled"] = ProcessInfo.processInfo.isLowPowerModeEnabled
        deviceInfo["Battery Level"] = getBatteryLevel()
        return deviceInfo
    }

    /// Get the current battery level of the device.
    /// Battery level ranges from 0 (fully discharged) to 100 (fully charged).
    /// For simulator where the battery levels are not available -1 is returned.
    ///
    ///- Returns: An `Int` representing the battery level of the device
    private static func getBatteryLevel() -> Int {
        let batteryPercentage = Int(UIDevice.current.batteryLevel * 100)
        return (batteryPercentage) > 0 ? batteryPercentage : -1
    }

    /// - Returns: A `String` representing the device's location authorization status
    private static func getAuthStatusString(authStatus: CLAuthorizationStatus) -> String {
        switch authStatus {
        case .notDetermined:
            return "Not Determined"
        case .restricted:
            return "Restricted"
        case .denied:
            return "Denied"
        case .authorizedAlways:
            return "Always"
        case .authorizedWhenInUse:
            return "When in use"
        @unknown default:
            return "Unknown"
        }
    }

    /// - Returns: A `String` representing the Apple device type
    private static func getDeviceType() -> String {
        switch UIDevice.current.userInterfaceIdiom {
        case .unspecified:
            return "Unspecified"
        case .phone:
            return "iPhone or iPod touch"
        case .pad:
            return "iPad"
        case .tv:
            return "Apple TV"
        case .carPlay:
            return "Apple Car Play"
        case .mac:
            return "Mac"
        @unknown default:
            return "Unspecified"
        }
    }

}
