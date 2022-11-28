/*
 Copyright 2022 Adobe. All rights reserved.
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

extension AssuranceSessionOrchestrator: AssurancePresentationDelegate {
    func initializePinScreenFlow() {
        authorizingPresentation = AssuranceAuthorizingPresentation(presentationDelegate: self, viewType: .pinCode)
        authorizingPresentation?.show()
    }

    func pinScreenConnectClicked(_ pin: String) {
        guard let session = session else {
            Log.error(label: AssuranceConstants.LOG_TAG, "PIN confirmation without active session.")
            terminateSession()
            return
        }

        /// display the error if the pin is empty
        if pin.isEmpty {
            authorizingPresentation?.sessionConnectionError(error: .noPincode)
            terminateSession()
            return
        }

        /// display error if the OrgID is missing.
        guard let orgID = stateManager.getURLEncodedOrgID() else {
            authorizingPresentation?.sessionConnectionError(error: .noOrgId)
            terminateSession()
            return
        }
        
        authorizingPresentation?.sessionConnecting()
        Log.trace(label: AssuranceConstants.LOG_TAG, "Connect Button clicked. Starting a socket connection.")
        session.sessionDetails.authenticate(withPIN: pin, andOrgID: orgID)
        session.startSession()
    }
    
    func pinScreenCancelClicked() {
        Log.trace(label: AssuranceConstants.LOG_TAG, "Cancel clicked. Terminating session and dismissing the PinCode Screen.")
        terminateSession()
    }

    func disconnectClicked() {
        Log.trace(label: AssuranceConstants.LOG_TAG, "Disconnect clicked. Terminating session.")
        terminateSession()
    }

    var isConnected: Bool {
        get {
            return session?.socket.socketState == .open
        }
    }
    
#if DEBUG
    
    func quickConnectBegin() {
        quickConnectManager?.createDevice()
    }
    
    func quickConnectCancelled() {
        quickConnectManager?.cancelRetryGetDeviceStatus()
    }
    
    func createQuickConnectSession(with sessionDetails: AssuranceSessionDetails) {
        if session != nil {
            Log.warning(label: AssuranceConstants.LOG_TAG, "Quick connect attempted when active session exists")
            return
        }
        
        authorizingPresentation?.sessionConnecting()
        createSession(withDetails: sessionDetails)
    }
    
    func quickConnectError(error: AssuranceConnectionError) {
        session?.handleConnectionError(error: error, closeCode: AssuranceConstants.SocketCloseCode.NORMAL_CLOSURE)
    }
#endif
}
