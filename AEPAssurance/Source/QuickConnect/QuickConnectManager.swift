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

import Foundation

class QuickConnectManager {

    private let parentExtension: Assurance
    private let view: QuickConnectView

    init(assurance: Assurance) {
        parentExtension = assurance
        view = QuickConnectView()
        detectShakeGesture()
    }

    func detectShakeGesture() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(handleShakeGesture),
                                               name: NSNotification.Name(AssuranceConstants.QuickConnect.SHAKE_NOTIFICATION_KEY),
                                               object: nil)
    }

    @objc private func handleShakeGesture() {
        parentExtension.shouldProcessEvents = true
        // parentExtension.invalidateTimer()
        DispatchQueue.main.async {
            // self.view?.appear()
        }
    }

}
