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
#if os(iOS)
import WebKit

class ErrorView: FullscreenMessageDelegate {
    var displayed: Bool = false
    var fullscreenMessage: FullscreenPresentable?
    var fullscreenWebView: WKWebView?
    let error: AssuranceConnectionError

    required init(_ error: AssuranceConnectionError) {
        self.error = error
    }

    func display() {
        // Use the UIService to create a fullscreen message with the `ErrorDialogHTML` and show to the user.
        fullscreenMessage = ServiceProvider.shared.uiService.createFullscreenMessage(payload: String(bytes: ErrorDialogHTML.content, encoding: .utf8) ?? "", listener: self, isLocalImageUsed: false)
        fullscreenMessage?.show()
    }
}

extension ErrorView: FullscreenMessageDelegate {
    func onShow(message: FullscreenMessage) {
        fullscreenWebView = message.webView as? WKWebView
    }

    func onDismiss(message: FullscreenMessage) {
        fullscreenMessage = nil
        fullscreenWebView = nil
    }

    func overrideUrlLoad(message: FullscreenMessage, url: String?) -> Bool {
        // no operation if we are unable to find the host of the url
        // return true, so force core to handle the URL
        guard let host = URL(string: url ?? "")?.host else {
            return true
        }

        // when the user hits "Cancel" on the iOS error screen. Dismiss the fullscreen message
        // return false, to indicate that the URL has been handled
        if host == AssuranceConstants.HTMLURLPath.CANCEL {
            message.dismiss()
            return false
        }

        return true
    }

    func webViewDidFinishInitialLoading(webView: WKWebView) {
        showErrorDialogToUser()
    }

    func onShowFailure() {
        Log.warning(label: AssuranceConstants.LOG_TAG, "Unable to display the error screen, onShowFailure delegate method is invoked")
    }

    private func showErrorDialogToUser() {
        Log.debug(label: AssuranceConstants.LOG_TAG, "Showing error dialog to user with error name: \(error.info.name) and description: \(error.info.description)")
        fullscreenWebView?.evaluateJavaScript(String(format: "showError('%@','%@', 0);", error.info.name, error.info.description), completionHandler: nil)
    }
}
#else
import AEPServices
import Foundation
import SwiftUI

struct ErrorMessageView: View {
    let error: AssuranceConnectionError

    var body: some View {
        VStack(spacing: 20) {
            Text(error.info.name)
                .font(.title)
                .fontWeight(.bold)

            Text(error.info.description)
                .font(.body)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Button("OK") {
                // This will be handled by the delegate
            }
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(8)
        }
        .padding()
    }
}

class ErrorView: FullscreenMessageNativeDelegate {
    var displayed: Bool = false
    var fullscreenMessage: FullscreenPresentable?
    let error: AssuranceConnectionError

    required init(_ error: AssuranceConnectionError) {
        self.error = error
    }

    func display() {
        // Create a FullscreenMessageNative with the error view
        let errorView = ErrorMessageView(error: error)
        fullscreenMessage = ServiceProvider.shared.uiService.createFullscreenMessage(payload: errorView, listener: self)
        fullscreenMessage?.show()
    }

    // MARK: - FullscreenMessageNativeDelegate

    func onShow(message: FullscreenMessageNative) {
        displayed = true
        Log.debug(label: AssuranceConstants.LOG_TAG, "Showing error dialog to user with error name: \(error.info.name) and description: \(error.info.description)")
    }

    func onDismiss(message: FullscreenMessageNative) {
        displayed = false
        fullscreenMessage = nil
    }
}
#endif

