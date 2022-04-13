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

class MockPresentation : AssurancePresentation {
    
    var expectation: XCTestExpectation?
    required override  init(stateManager: AssuranceStateManager, sessionOrchestrator: AssuranceSessionOrchestrator) {
        super.init(stateManager: stateManager, sessionOrchestrator: sessionOrchestrator)
    }
    
    var onSessionConnectedCalled = false
    override func onSessionConnected() {
        onSessionConnectedCalled = true
    }
    
    var onSessionReconnectingCalled = false
    override func onSessionReconnecting() {
        onSessionReconnectingCalled = true
    }
    
    var onSessionDisconnectedCalled = false
    override func onSessionDisconnected() {
        onSessionDisconnectedCalled = true
    }
    
    var onSessionConnectionErrorCalled = false
    var onSessionConnectionErrorValue : AssuranceConnectionError?
    override func onSessionConnectionError(error: AssuranceConnectionError) {
        onSessionConnectionErrorCalled = true
        onSessionConnectionErrorValue = error
    }
    
    var addClientLogCalled = false
    var addClientLogMessage: String?
    var addClientLogVisibility: AssuranceClientLogVisibility?
    override func addClientLog(_ message: String, visibility: AssuranceClientLogVisibility) {
        addClientLogCalled = true
        addClientLogMessage = message
        addClientLogVisibility = visibility
    }
}

