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
import Foundation
import XCTest

class MockAssuranceSession: AssuranceSession {
    var expectation: XCTestExpectation?
    override init(_ assuranceExtension: Assurance) {
        super.init(assuranceExtension)
        socket = MockSocket(withDelegate: self)
    }

    var sendEventCalled = false
    var sentEvent: AssuranceEvent?

    override func sendEvent(_ assuranceEvent: AssuranceEvent) {
        expectation?.fulfill()
        sendEventCalled = true
        sentEvent = assuranceEvent
    }

    var addClientLogCalled = false
    var addClientLogMessage: String?
    var addClientLogVisibility: AssuranceClientLogVisibility?
    override func addClientLog(_ message: String, visibility: AssuranceClientLogVisibility) {
        addClientLogCalled = true
        addClientLogMessage = message
        addClientLogVisibility = visibility
    }

    var terminateSessionCalled = false
    override func terminateSession() {
        terminateSessionCalled = true
    }

    func mockSocketState(state: SocketState) {
        if let mockSocket = socket as? MockSocket {
            mockSocket.mockSocketState(state: state)
        }
    }
}
