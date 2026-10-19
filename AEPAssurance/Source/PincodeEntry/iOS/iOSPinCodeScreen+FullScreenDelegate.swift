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
import WebKit

extension iOSPinCodeScreen: @preconcurrency FullscreenMessageDelegate {

    /// Invoked when the fullscreen message is displayed
    /// - Parameters:
    ///     - message: Fullscreen message which is currently shown
    nonisolated func onShow(message: FullscreenMessage) {
        let webView = message.webView as? WKWebView
        DispatchQueue.main.async {
            self.displayed = true
            self.fullscreenWebView = webView
            Log.trace(label: AssuranceConstants.LOG_TAG, "PinCode Screen loaded and awaiting input from user.")
        }
    }

    /// Invoked when the fullscreen message is dismissed
    /// - Parameters:
    ///     - message: Fullscreen message which is dismissed
    nonisolated func onDismiss(message: FullscreenMessage) {
        DispatchQueue.main.async {
            self.displayed = false
            self.fullscreenWebView = nil
            self.fullscreenMessage = nil
        }
    }

    /// Invoked when the fullscreen message is attempting to load a url
    /// - Parameters:
    ///     - message: Fullscreen message
    ///     - url:     String the url being loaded by the message
    /// - Returns: True if the core wants to handle the URL (and not the fullscreen message view implementation)
    nonisolated func overrideUrlLoad(message: FullscreenMessage, url: String?) -> Bool {

        // no operation if we are unable to find the host of the url
        // return true, so force core to handle the URL
        guard let host = URL(string: url ?? "")?.host else {
            return true
        }

        // when the user hits "Cancel" on the iOS pinpad screen. Dismiss the fullscreen message
        // return false, to indicate that the URL has been handled
        if host == AssuranceConstants.HTMLURLPath.CANCEL {
            message.dismiss()
            DispatchQueue.main.async {
                self.presentationDelegate.pinScreenCancelClicked()
            }
            return false
        }

        // when the user hit connect button
        // return false, to indicate that the URL has been handled
        if host == AssuranceConstants.HTMLURLPath.CONFIRM {
            // get the entered 4 digit code from url
            let pin = URL(string: url ?? "")?.params["code"] ?? ""
            DispatchQueue.main.async {
                self.presentationDelegate.pinScreenConnectClicked(pin)
            }
            return false
        }

        return true
    }

    ///
    /// Invoked when the FullscreenMessage failed to be displayed
    ///
    nonisolated func onShowFailure() {
        Log.warning(label: AssuranceConstants.LOG_TAG, "Unable to display the pincode screen, onShowFailure delegate method is invoked")
    }

}
