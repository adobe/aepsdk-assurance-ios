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
@testable import AEPCore
import Foundation
import XCTest

class MockStatusUI: iOSStatusUI {
    
    
    required init(presentationDelegate: AssurancePresentationDelegate) {
        super.init(presentationDelegate: presentationDelegate)
    }
    
    var displayCalled = false
    override func display() {
        displayCalled = true
    }

    var removeCalled = false
    override func remove() {
        removeCalled = true
    }

    var updateForSocketConnectedCalled = false
    override func updateForSocketConnected() {
        updateForSocketConnectedCalled = true
    }

    var updateForSocketInActiveCalled = false
    override func updateForSocketInActive() {
        updateForSocketInActiveCalled = true
    }

    var addClientLogCalled = false
    var addClientLogMessage : String?
    var addClientLogVisibility : AssuranceClientLogVisibility?
    override func addClientLog(_ message: String, visibility: AssuranceClientLogVisibility) {
        addClientLogCalled = true
        addClientLogMessage = message
        addClientLogVisibility = visibility
    }

}
