//
// Copyright 2021 Adobe. All rights reserved.
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

    let stateManager: AssuranceStateManager
    let sessionOrchestrator: AssuranceSessionOrchestrator

    lazy var pinCodeScreen: SessionAuthorizingUI = {
        iOSPinCodeScreen.init(withState: stateManager)
    }()

    lazy var statusUI: iOSStatusUI  = {
        iOSStatusUI.init(withSessionOrchestrator: sessionOrchestrator)
    }()

    init(stateManager: AssuranceStateManager, sessionOrchestrator: AssuranceSessionOrchestrator) {
        self.stateManager = stateManager
        self.sessionOrchestrator = sessionOrchestrator
    }

    ///
    /// Adds the log to Assurance Status UI.
    /// - Parameters:
    ///     - message: `String` log message
    ///     - visibility: an `AssuranceClientLogVisibility` determining the importance of the log message
    ///
    func addClientLog(_ message: String, visibility: AssuranceClientLogVisibility) {
        statusUI.addClientLog(message, visibility: visibility)
    }

    func onSessionInitialized() {
        // invoke the pinpad screen and create a socketURL with the pincode and other essential parameters
        pinCodeScreen.show(callback: { [weak self]  socketURL, error in
            if let error = error {
                self?.onSessionConnectionError(error: error)
                return
            }

            guard let socketURL = socketURL else {
                Log.debug(label: AssuranceConstants.LOG_TAG, "SocketURL to connect to session is empty. Ignoring to start Assurance session.")
                return
            }

            // Thread : main thread (this callback is called from `overrideUrlLoad` method of WKWebView)
            Log.debug(label: AssuranceConstants.LOG_TAG, "Attempting to make a socket connection with URL : \(socketURL)")
            self?.sessionOrchestrator.onPinConfirmation(socketURL)
            self?.pinCodeScreen.connectionInitialized()
        })
    }

    func onSessionConnected() {
        if pinCodeScreen.isDisplayed {
            self.pinCodeScreen.connectionSucceeded()
        }

        self.statusUI.display()
        self.statusUI.updateForSocketConnected()
    }

    func onSessionReconnecting() {
        if !statusUI.isDisplayed {
            statusUI.display()
        }
        statusUI.updateForSocketInActive()
    }

    func onSessionDisconnected() {
        pinCodeScreen.connectionFinished()
        statusUI.remove()
    }

    func onSessionConnectionError(error: AssuranceConnectionError) {
        if pinCodeScreen.isDisplayed == true {
            if error == .userCancelled {
                sessionOrchestrator.onDisconnect()
                return
            }

            pinCodeScreen.connectionFailedWithError(error)
        } else {
            let errorView = ErrorView.init(AssuranceConnectionError.clientError)
            errorView.display()
        }

        if !error.info.shouldRetry {
            statusUI.remove()
        }
    }
}
