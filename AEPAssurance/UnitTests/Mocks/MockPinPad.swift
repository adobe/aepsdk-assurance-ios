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

@testable import AEPAssurance
@testable import AEPServices
import Foundation

class MockPinPad: SessionAuthorizingUI {
    var isDisplayed: Bool

    required init(withExtension _: Assurance) {
        isDisplayed = false
    }

    var callback: PinCodeCallback?
    func show(callback: @escaping PinCodeCallback) {
        isDisplayed = true
        self.callback = callback
    }

    var connectionInitializedCalled = false
    func connectionInitialized() {
        connectionInitializedCalled = true
    }

    var connectionSucceededCalled = false
    func connectionSucceeded() {
        connectionSucceededCalled = true
    }

    var connectionFinishedCalled = false
    func connectionFinished() {
        connectionFinishedCalled = true
    }

    var connectionFailedWithErrorCalled = false
    var connectionFailedWithErrorValue: AssuranceConnectionError?
    func connectionFailedWithError(_ error: AssuranceConnectionError) {
        connectionFailedWithErrorCalled = true
        connectionFailedWithErrorValue = error
    }
}
