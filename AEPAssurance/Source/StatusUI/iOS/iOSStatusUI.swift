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

//#if os(iOS)
import AEPServices
import Foundation
#if os(iOS)
import WebKit
import UIKit
import SwiftUI
#else
import TVUIKit
import SwiftUI
#endif

class iOSStatusUI: StatusUIPresentable {
    var displayed: Bool = false
    var clientLogQueue: ThreadSafeQueue<AssuranceClientLogMessage>
    var floatingButton: FloatingButtonPresentable?
    var fullScreenMessage: FullscreenPresentable?
    var presentationDelegate: AssurancePresentationDelegate
    #if os(tvOS)
    private var statusView: AssuranceStatusView?
    private let statusViewModel = AssuranceStatusViewModel()
    #endif

    required init(presentationDelegate: AssurancePresentationDelegate) {
        self.presentationDelegate = presentationDelegate
        self.clientLogQueue = ThreadSafeQueue(withLimit: 100)
        #if os(tvOS)
        setupStatusView()
        #endif
    }

    #if os(tvOS)
    private func setupStatusView() {
        let statusView = AssuranceStatusView(
            viewModel: statusViewModel,
            onDisconnect: { [weak self] in
                guard let self = self else { return }
                self.presentationDelegate.disconnectClicked()
                self.fullScreenMessage?.dismiss()
            },
            onCancel: { [weak self] in
                self?.fullScreenMessage?.dismiss()
                self?.floatingButton?.show()
            }
        )
        self.statusView = statusView
    }
    #endif

    /// Displays the Assurance Status UI on the customers application.
    /// This method will initialize the FloatingButton and the Status UI required for displaying Assurance status.
    /// On calling this method Floating button appears on the screen showing the current connection status.
    func display() {
        if floatingButton != nil {
            return
        }

        if fullScreenMessage == nil {
            #if os(iOS)
            self.fullScreenMessage = ServiceProvider.shared.uiService.createFullscreenMessage(payload: String(bytes: StatusInfoHTML.content, encoding: .utf8) ?? "", listener: self, isLocalImageUsed: false)
            #else
            guard let statusView = self.statusView else { return }
            self.fullScreenMessage = ServiceProvider.shared.uiService.createFullscreenMessage(payload: statusView, listener: self)
            #endif
        }

        floatingButton = ServiceProvider.shared.uiService.createFloatingButton(listener: self)
        floatingButton?.setInitial(position: FloatingButtonPosition.topRight)
        floatingButton?.show()
        displayed = true
    }

    ///
    /// Removes Assurance Status UI from the customers application
    ///
    func remove() {
        self.fullScreenMessage = nil
        #if os(tvOS)
        self.statusView = nil
        #endif

        // Only dismiss the floating button if we're actually disconnecting
        if !displayed {
            self.floatingButton?.dismiss()
            self.floatingButton = nil
        }
        displayed = false
    }

    ///
    /// Updates Assurance Status UI to denote socket is currently connected.
    ///
    func updateForSocketConnected() {
        addClientLog("Assurance connection established.", visibility: .low)
        floatingButton?.setButtonImage(imageData: Data(bytes: ActiveIcon.content, count: ActiveIcon.content.count))
    }

    ///
    /// Updates Assurance Status UI to denote socket connection is currently inactive.
    ///
    func updateForSocketInActive() {
        addClientLog("Attempting to reconnect..", visibility: .low)
        floatingButton?.setButtonImage(imageData: Data(bytes: InactiveIcon.content, count: InactiveIcon.content.count))
    }

    ///
    /// Appends the logs to Assurance Status UI
    /// - Parameters:
    ///     - message: `String` log message.
    ///     - visibility: an `AssuranceClientLogVisibility` determining the importance of the log message.
    ///
    func addClientLog(_ message: String, visibility: AssuranceClientLogVisibility) {
        clientLogQueue.enqueue(newElement: AssuranceClientLogMessage(withVisibility: visibility, andMessage: message))
        updateLogUI()
    }

    ///
    /// Load and display all the pending log messages on Assurance Status UI.
    ///
    func updateLogUI() {
        DispatchQueue.main.async {
            while self.clientLogQueue.size() > 0 {
                guard let logMessage = self.clientLogQueue.dequeue() else {
                    return
                }
                #if os(iOS)
                self.updateLogInHTML(logMessage)
                #else
                Log.debug(label: AssuranceConstants.LOG_TAG, "Adding log message to status view: \(logMessage.message)")
                self.statusViewModel.addLog(logMessage.message, visibility: logMessage.visibility)
                #endif
            }
        }
    }

    private func updateLogInHTML(_ message: AssuranceClientLogMessage) {
        #if os(iOS)
        if let fullscreenMessage = fullScreenMessage as? FullscreenMessage {
            let script = "addLog('\(message.message)', '\(message.visibility.rawValue)');"
            fullscreenMessage.webView?.evaluateJavaScript(script, completionHandler: nil)
        }
        #endif
    }
}

#if os(iOS)
extension iOSStatusUI: FullscreenMessageDelegate {
    func onShow(message: FullscreenMessage) {
        displayed = true
        Log.debug(label: AssuranceConstants.LOG_TAG, "Status UI fullscreen message displayed")
    }

    func onDismiss(message: FullscreenMessage) {
        Log.debug(label: AssuranceConstants.LOG_TAG, "Status UI fullscreen message dismissing, webView is \(message.webView == nil ? "nil" : "not nil")")
        displayed = false
        fullScreenMessage = nil
        // Dismiss floating button after fullscreen is dismissed during disconnect
        if message.webView == nil {
            floatingButton?.dismiss()
            floatingButton = nil
        }
        Log.debug(label: AssuranceConstants.LOG_TAG, "Status UI fullscreen message dismissed")
    }

    func overrideUrlLoad(message: FullscreenMessage, url: String?) -> Bool {
        guard let host = URL(string: url ?? "")?.host else {
            return true
        }

        if host == AssuranceConstants.HTMLURLPath.CANCEL {
            Log.debug(label: AssuranceConstants.LOG_TAG, "Cancel clicked, hiding fullscreen message")
            message.hide()
            floatingButton?.show()
            return false
        }

        if host == AssuranceConstants.HTMLURLPath.DISCONNECT {
            Log.debug(label: AssuranceConstants.LOG_TAG, "Disconnect clicked, dismissing fullscreen message")
            // First notify delegate about disconnect
            presentationDelegate.disconnectClicked()
            // Then dismiss the fullscreen message which will trigger onDismiss
            message.dismiss()
            return false
        }

        return true
    }

    func onShowFailure() {
        Log.warning(label: AssuranceConstants.LOG_TAG, "Unable to display the statusUI screen, onShowFailure delegate method is invoked")
    }
}
#else
extension iOSStatusUI: FullscreenMessageNativeDelegate {
    func onShow(message: FullscreenMessageNative) {
        displayed = true
        Log.debug(label: AssuranceConstants.LOG_TAG, "Status UI fullscreen message displayed")
    }

    func onDismiss(message: FullscreenMessageNative) {
        displayed = false
        displayed = false
        Log.debug(label: AssuranceConstants.LOG_TAG, "Status UI fullscreen message dismissed")
    }
}
#endif
