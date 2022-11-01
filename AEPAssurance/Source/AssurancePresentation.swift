//
// Copyright 2022 Adobe. All rights reserved.
// This file is licensed to you under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License. You may obtain a copy
// of the License at http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software distributed under
// the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR REPRESENTATIONS
// OF ANY KIND, either express or implied. See the License for the specific language
// governing permissions and limitations under the License.
//

import AEPServices
import Foundation

class AssurancePresentation {

    let delegate: AssurancePresentationDelegate

    lazy var pinCodeScreen: SessionAuthorizingUI = {
        iOSPinCodeScreen.init(withPresentationDelegate: delegate)
    }()

    lazy var statusUI: iOSStatusUI  = {
        iOSStatusUI.init(presentationDelegate: delegate)
    }()

    init(presentationDelegate: AssurancePresentationDelegate) {
        self.delegate = presentationDelegate
    }

    /// Adds the log message o Assurance session's Status UI.
    /// - Parameters:
    ///     - message: `String` log message
    ///     - visibility: an `AssuranceClientLogVisibility` determining the importance of the log message
    func addClientLog(_ message: String, visibility: AssuranceClientLogVisibility) {
        statusUI.addClientLog(message, visibility: visibility)
    }

    /// Call this to show the UI elements that are required when a session is initialized.
    func sessionInitialized() {
        // invoke the pinpad screen and create a socketURL with the pincode and other essential parameters
        pinCodeScreen.show()
    }

    /// Call this to show the UI elements that are required when a session connection has been successfully established.
    func sessionConnected() {
        if pinCodeScreen.displayed {
            self.pinCodeScreen.sessionConnected()
        }

        self.statusUI.display()
        self.statusUI.updateForSocketConnected()
    }

    /// Call this to show the UI elements that are required when a session is attempting to reconnect.
    func sessionReconnecting() {
        if !statusUI.displayed {
            statusUI.display()
        }
        statusUI.updateForSocketInActive()
    }

    /// Call this method to clear the UI elements when a session is disconnected.
    func sessionDisconnected() {
        pinCodeScreen.sessionDisconnected()
        statusUI.remove()
    }

    /// Call this to show the UI elements that are required when a session has connection error.
    func sessionConnectionError(error: AssuranceConnectionError) {
        if pinCodeScreen.displayed == true {
            pinCodeScreen.sessionConnectionFailed(withError: error)
        } else {
            let errorView = ErrorView.init(AssuranceConnectionError.clientError)
            errorView.display()
        }

        if !error.info.shouldRetry {
            statusUI.remove()
        }
    }
}
