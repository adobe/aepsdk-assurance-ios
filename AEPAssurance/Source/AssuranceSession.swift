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
import Foundation

class AssuranceSession {
    let assuranceExtension: Assurance
    var pinCodeScreen: SessionAuthorizing?

    /// Initializer with instance of  `Assurance` extension
    init(_ assuranceExtension: Assurance) {
        self.assuranceExtension = assuranceExtension
    }

    /// Called when a valid assurance deeplink url is received from the startSession API
    /// Calling this method will attempt to display the pincode screen for session authentication
    ///
    /// Thread : Listener thread from EventHub
    func startSession() {
        let pinCodeScreen = iOSPinCodeScreen.init(withExtension: assuranceExtension)
        self.pinCodeScreen = pinCodeScreen

        pinCodeScreen.getSocketURL(callback: { socketUrl in
            Log.debug(label: AssuranceConstants.LOG_TAG, "Attempting to make a socket connection with URL : \(socketUrl)")
            pinCodeScreen.connectionInitialized()
        })

    }

    func sendEvent(_ assuranceEvent: AssuranceEvent) {
        // coming soon
    }

}
