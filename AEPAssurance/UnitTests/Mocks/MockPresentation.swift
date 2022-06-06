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
    required override  init(sessionOrchestrator: AssuranceSessionOrchestrator) {
        super.init(sessionOrchestrator: sessionOrchestrator)
    }
    
    var sessionInitializedCalled = false
    override func sessionInitialized() {
        sessionInitializedCalled = true
    }
    
    var sessionConnectedCalled = false
    override func sessionConnected() {
        sessionConnectedCalled = true
    }
    
    var sessionReconnectingCalled = false
    override func sessionReconnecting() {
        sessionReconnectingCalled = true
    }
    
    var sessionDisconnectedCalled = false
    override func sessionDisconnected() {
        sessionDisconnectedCalled = true
    }
    
    var sessionConnectionErrorCalled = false
    var sessionConnectionErrorValue : AssuranceConnectionError?
    override func sessionConnectionError(error: AssuranceConnectionError) {
        sessionConnectionErrorCalled = true
        sessionConnectionErrorValue = error
    }
    
    var addClientLogCalled = XCTestExpectation(description: "Add Client log message not called")
    var addClientLogCalledTimes = 0
    var addClientLogMessage: String?
    var addClientLogVisibility: AssuranceClientLogVisibility?
    override func addClientLog(_ message: String, visibility: AssuranceClientLogVisibility) {
        addClientLogCalled.fulfill()
        addClientLogCalledTimes += 1
        addClientLogMessage = message
        addClientLogVisibility = visibility
    }
}

