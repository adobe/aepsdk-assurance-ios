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

class AssuranceSessionOrchestrator: AssurancePresentationDelegate {

    let stateManager: AssuranceStateManager
    #if DEBUG
    var session: AssuranceSession?
    #else
    private(set) var session: AssuranceSession?
    #endif

    init(stateManager: AssuranceStateManager) {
        self.stateManager = stateManager
    }

    func createSession() {

    }

    func terminateSession() {

    }

    func shutDownSession() {

    }

    func sendEvent(_ assuranceEvent: AssuranceEvent) {

    }

    // MARK: - AssurancePresentationDelegate methods

    func pinScreenConnectClicked(_ pin: String) {
        // display the error if the pin is empty
        if pin.isEmpty {
            session?.presentation.sessionConnectionError(error: .noPincode)
            return
        }

        // display error if the sessionId is invalid.
        guard let sessionId = stateManager.sessionId else {
            session?.presentation.sessionConnectionError(error: .noSessionID)
            return
        }

        // display error if the OrgID is missing.
        guard let orgID = stateManager.getURLEncodedOrgID() else {
            session?.presentation.sessionConnectionError(error: .noOrgId)
            return
        }

        // wss://connect%@.griffon.adobe.com/client/v1?sessionId=%@&token=%@&orgId=%@&clientId=%@
        let socketURL = String(format: AssuranceConstants.BASE_SOCKET_URL,
                               stateManager.environment.urlFormat,
                               sessionId,
                               pin,
                               orgID,
                               stateManager.clientID)

        guard let url = URL(string: socketURL) else {
            session?.presentation.sessionConnectionError(error: .noURL)
            return
        }

        Log.trace(label: AssuranceConstants.LOG_TAG, "Connect Button clicked. Making a socket connection with url \(url).")
        // todo - connect to a session with the pin
        // session.connect(pin)
    }

    func pinScreenCancelClicked() {
        Log.trace(label: AssuranceConstants.LOG_TAG, "Cancel clicked. Terminating session and dismissing the PinCode Screen.")
        terminateSession()
    }

    func disconnectClicked() {
        Log.trace(label: AssuranceConstants.LOG_TAG, "Disconnect clicked. Terminating session.")
        terminateSession()
    }

}
