//
// Copyright 2024 Adobe. All rights reserved.
// This file is licensed to you under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License. You may obtain a copy
// of the License at http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software distributed under
// the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR REPRESENTATIONS
// OF ANY KIND, either express or implied. See the License for the specific language
// governing permissions and limitations under the License.
//

#if os(tvOS)
import SwiftUI

class QuickConnectViewModel: ObservableObject {
    @Published var displayed = false
    @Published var isWaiting = false
    @Published var showError = false
    @Published var errorTitleText = ""
    @Published var errorDescriptionText = ""
    @Published var isConnected = false

    let presentationDelegate: AssurancePresentationDelegate

    init(presentationDelegate: AssurancePresentationDelegate) {
        self.presentationDelegate = presentationDelegate
    }

    // MARK: Actions from the UI
    func cancelClicked() {
        presentationDelegate.quickConnectCancelled()
        dismiss()
    }

    func connectClicked() {
        waitingState()
        presentationDelegate.quickConnectBegin()
    }

    // MARK: States
    func initialState() {
        isWaiting = false
        showError = false
        isConnected = false
    }

    func waitingState() {
        showError = false
        isWaiting = true
    }

    func connectionSuccessfulState() {
        isConnected = true
    }

    func errorState(errorTitle: String, errorText: String) {
        errorTitleText = errorTitle
        errorDescriptionText = errorText
        showError = true
        isWaiting = false
        isConnected = false
    }

    func dismiss() {
        isWaiting = false
        displayed = false
    }

    // MARK: SessionAuthorizingUI Methods
    func sessionConnecting() {
        // No op for quick connect screen
    }

    func sessionConnected() {
        // Dismiss after setting connected
        DispatchQueue.main.async {
            self.connectionSuccessfulState()
            self.dismiss()
        }
    }

    func sessionDisconnected() {
        DispatchQueue.main.async {
            self.dismiss()
        }
    }

    func sessionConnectionFailed(withError error: AssuranceConnectionError) {
        DispatchQueue.main.async {
            self.errorState(errorTitle: error.info.name, errorText: error.info.description)
        }
    }

    // UI elements
    func connectionImage() -> Image {
        if let uiImage = UIImage(data: Data(bytes: AEPAssurance.connectionImage.content, count: AEPAssurance.connectionImage.content.count)) {
            return Image(uiImage: uiImage)
        } else {
            return Image(systemName: "link")
        }
    }

    func adobeLogoImage() -> Image {
        if let uiImage = UIImage(data: Data(bytes: adobelogo.content, count: adobelogo.content.count)) {
            return Image(uiImage: uiImage)
        } else {
            return Image(systemName: "a.circle")
        }
    }
}
#endif
