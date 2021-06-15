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
    let RECONNECT_TIMEOUT = 5
    let assuranceExtension: Assurance
    var pinCodeScreen: SessionAuthorizingUI?
    let outboundQueue: ThreadSafeQueue = ThreadSafeQueue<AssuranceEvent>(withLimit: 200)
    let inboundQueue: ThreadSafeQueue = ThreadSafeQueue<AssuranceEvent>(withLimit: 200)
    let inboundSource: DispatchSourceUserDataAdd = DispatchSource.makeUserDataAddSource(queue: DispatchQueue.global(qos: .default))
    let outboundSource: DispatchSourceUserDataAdd = DispatchSource.makeUserDataAddSource(queue: DispatchQueue.global(qos: .default))
    let pluginHub: PluginHub = PluginHub()

    lazy var socket: SocketConnectable  = {
        return WebViewSocket(withDelegate: self)
    }()

    lazy var statusUI: iOSStatusUI  = {
        iOSStatusUI.init(withSession: self)
    }()

    // MARK: - boolean flags

    /// indicates if the session is currently attempting to reconnect. This flag is set when the session disconnects due to some retry-able reason,
    /// This flag is reset when the session is connected or successfully terminated
    var isAttemptingToReconnect: Bool = false

    /// indicates if Assurance SDK can start forwarding events to the session. This flag is set when a command `startForwarding` is received from the socket.
    var canStartForwarding: Bool = false

    /// true indicates Assurance SDK has timeout and shutdown after non-reception of deep link URL because of which it  has cleared all the queued initial SDK events from memory.
    var didClearBootEvent: Bool = false

    /// Initializer with instance of  `Assurance` extension
    init(_ assuranceExtension: Assurance) {
        self.assuranceExtension = assuranceExtension
        handleInBoundEvents()
        handleOutBoundEvents()
        registerInternalPlugins()
    }

    /// Called when a valid assurance deep link url is received from the startSession API
    /// Calling this method will attempt to display the pinCode screen for session authentication
    ///
    /// Thread : Listener thread from EventHub
    func startSession() {
        let pinCodeScreen = iOSPinCodeScreen.init(withExtension: assuranceExtension)
        self.pinCodeScreen = pinCodeScreen

        pinCodeScreen.show(callback: { [weak self] socketURL, error in
            // Thread : main thread (this callback is called from `overrideUrlLoad` method of WKWebView)
            if let error = error {
                self?.handleConnectionError(error: error, closeCode: nil)
                return
            }

            guard let socketURL = socketURL else {
                Log.debug(label: AssuranceConstants.LOG_TAG, "SocketURL to connect to session is empty. Ignoring to start Assurance session.")
                return
            }

            Log.debug(label: AssuranceConstants.LOG_TAG, "Attempting to make a socket connection with URL : \(socketURL.absoluteString)")
            self?.socket.connect(withUrl: socketURL)
            pinCodeScreen.connectionInitialized()
        })
    }

    ///
    /// Terminates the ongoing Assurance session.
    ///
    func terminateSession() {
        socket.disconnect()
        clearSessionData()
    }

    ///
    /// Sends the `AssuranceEvent` to the connected session.
    /// - Parameter assuranceEvent - an `AssuranceEvent` to be forwarded
    ///
    func sendEvent(_ assuranceEvent: AssuranceEvent) {
        outboundQueue.enqueue(newElement: assuranceEvent)
        outboundSource.add(data: 1)
    }

    func handleConnectionError(error: AssuranceConnectionError, closeCode: Int?) {
        // coming soon
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

    ///
    /// Clears the queued SDK events from memory. Call this method once Assurance shut down timer is triggered.
    ///
    func clearQueueEvents() {
        inboundQueue.clear()
        outboundQueue.clear()
        didClearBootEvent = true
    }

    ///
    /// Clears all the data related to the current Assurance Session.
    /// Call this method when user terminates the Assurance session or when non-recoverable socket error occurs.
    ///
    func clearSessionData() {
        assuranceExtension.clearState()
        canStartForwarding = false
        pluginHub.notifyPluginsOnSessionTerminated()
        assuranceExtension.sessionId = nil
        assuranceExtension.connectedWebSocketURL = nil
        assuranceExtension.environment = AssuranceConstants.DEFAULT_ENVIRONMENT
        pinCodeScreen = nil
    }

    // MARK: - Private methods

    ///
    /// Registers all the available internal plugin with PluginHub.
    ///
    private func registerInternalPlugins() {
        pluginHub.registerPlugin(PluginFakeEvent(), toSession: self)
        pluginHub.registerPlugin(PluginConfigModify(), toSession: self)
        pluginHub.registerPlugin(PluginScreenshot(), toSession: self)
    }

}
