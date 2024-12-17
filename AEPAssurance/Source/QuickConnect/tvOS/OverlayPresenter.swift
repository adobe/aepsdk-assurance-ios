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
import Combine
import SwiftUI
import UIKit

class OverlayPresenter: SessionAuthorizingUI {
    var displayed: Bool { viewModel.displayed }

    private var window: UIWindow?
    private var hostingController: UIHostingController<QuickConnectSwiftUIView>!
    private let viewModel: QuickConnectViewModel

    // A set to store the dismiss signal observer.
    private var cancellables = Set<AnyCancellable>()

    required init(withPresentationDelegate presentationDelegate: AssurancePresentationDelegate) {
        self.viewModel = QuickConnectViewModel(presentationDelegate: presentationDelegate)
        let quickConnectView = QuickConnectSwiftUIView(viewModel: viewModel)
        DispatchQueue.main.async {
            self.hostingController = UIHostingController(rootView: quickConnectView)
        }

        // When `viewModel.displayed` changes, Combine can be used to listen for updates and trigger
        // dismissal. Alternatively, rely on `QuickConnectView` calling `viewModel.dismiss()` and
        // invoke `dismiss()` within a `.sink` if necessary.

        // Observe changes to `displayed` to auto-dismiss when it's set to false.
        // Subscribe once per class lifecycle.
        viewModel.$displayed
            .dropFirst()
            .sink { [weak self] isDisplayed in
                guard let self = self else { return }
                if !isDisplayed {
                    self.dismiss()
                }
            }
            .store(in: &cancellables)
    }

    func show() {
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene else {
            // Fallback if no scene is available
            return
        }

        let newWindow = UIWindow(windowScene: scene)
        newWindow.rootViewController = hostingController
        newWindow.windowLevel = .alert + 1
        self.window = newWindow
        newWindow.makeKeyAndVisible()
    }

    func dismiss() {
        window?.isHidden = true
        window = nil
    }

    // SessionAuthorizingUI methods
    func sessionConnecting() {
        viewModel.sessionConnecting()
    }

    func sessionConnected() {
        viewModel.sessionConnected()
    }

    func sessionDisconnected() {
        viewModel.sessionDisconnected()
    }

    func sessionConnectionFailed(withError error: AssuranceConnectionError) {
        viewModel.sessionConnectionFailed(withError: error)
    }
}
#endif
