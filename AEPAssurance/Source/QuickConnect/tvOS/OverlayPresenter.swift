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

    private var hostingController: UIHostingController<QuickConnectSwiftUIView>!
    private let viewModel: QuickConnectViewModel
    private weak var presentingViewController: UIViewController?

    // A set to store the dismiss signal observer.
    private var cancellables = Set<AnyCancellable>()

    required init(withPresentationDelegate presentationDelegate: AssurancePresentationDelegate) {
        self.viewModel = QuickConnectViewModel(presentationDelegate: presentationDelegate)
        let quickConnectView = QuickConnectSwiftUIView(viewModel: viewModel)
        DispatchQueue.main.async {
            self.hostingController = UIHostingController(rootView: quickConnectView)
            // Configure the hosting controller for tvOS
            self.hostingController.modalPresentationStyle = .blurOverFullScreen
            self.hostingController.view.backgroundColor = UIColor(white: 0, alpha: 0.8)
        }

        // Observe changes to `displayed` to handle dismissal
        viewModel.$displayed
            .dropFirst()
            .sink { [weak self] isDisplayed in
                guard let self = self else { return }
                if !isDisplayed {
                    self.dismissOverlay()
                }
            }
            .store(in: &cancellables)
    }

    func show() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self,
                  let window = UIApplication.shared.assuranceGetKeyWindow(),
                  let rootViewController = window.rootViewController else {
                return
            }

            // Store the presenting view controller for dismissal
            self.presentingViewController = rootViewController

            // Present modally
            rootViewController.present(self.hostingController, animated: true) {
                // Set initial focus if needed
                if let firstFocusableButton = self.hostingController.view.subviews.first(where: { $0 is UIButton }) {
                    firstFocusableButton.becomeFirstResponder()
                }
            }
        }
    }

    private func dismissOverlay() {
        DispatchQueue.main.async { [weak self] in
            self?.hostingController.dismiss(animated: true)
        }
    }

    func dismiss() {
        dismissOverlay()
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
