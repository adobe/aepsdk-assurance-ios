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

import SwiftUI

class PassthroughWindow: UIWindow {
    // To refine hit-testing so that only the button area is enabled, SwiftUI’s default hit
    // testing is currently used. If further customization is needed, override the `hitTest` method here.
}

class FloatingButtonPresenter {
    private var hostingController: UIHostingController<tvOSFloatingButton>?

    init(dismissAction: @escaping () -> Void) {
        let rootView = tvOSFloatingButton(dismissAction: dismissAction)
        hostingController = UIHostingController(rootView: rootView)
        hostingController?.view.backgroundColor = .clear
    }

    func show() {
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let mainWindow = scene.windows.first(where: { $0.isKeyWindow }) else {
            return
        }

        guard let hcView = hostingController?.view else { return }

        // Add the overlay as a subview of the main window
        mainWindow.addSubview(hcView)
        hcView.translatesAutoresizingMaskIntoConstraints = false

        // Pin the overlay to fill the entire window so it can position the button at bottom-right
        NSLayoutConstraint.activate([
            hcView.topAnchor.constraint(equalTo: mainWindow.topAnchor),
            hcView.leadingAnchor.constraint(equalTo: mainWindow.leadingAnchor),
            hcView.trailingAnchor.constraint(equalTo: mainWindow.trailingAnchor),
            hcView.bottomAnchor.constraint(equalTo: mainWindow.bottomAnchor)
        ])
        mainWindow.layoutIfNeeded()
    }

    func dismiss() {
        hostingController?.view.removeFromSuperview()
        hostingController = nil
    }
}
