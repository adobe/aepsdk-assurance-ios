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
import AEPServices
import XCTest

class MockSession: AssuranceSession {

    var expectation: XCTestExpectation?
    override init(sessionDetails: AssuranceSessionDetails, stateManager: AssuranceStateManager, sessionOrchestrator: AssuranceSessionOrchestrator, outboundEvents: ThreadSafeArray<AssuranceEvent>?) {
        super.init(sessionDetails: sessionDetails, stateManager: stateManager, sessionOrchestrator: sessionOrchestrator, outboundEvents: outboundEvents)
        self.socket = MockSocket(withDelegate: self)
    }


    var sendEventCalled = XCTestExpectation(description: "Send event method called expectation")
    var sentEvent: AssuranceEvent?
    override func sendEvent(_ assuranceEvent: AssuranceEvent) {
        sentEvent = assuranceEvent
        sendEventCalled.fulfill()
    }
    
    var startSessionCalled = XCTestExpectation(description: "Start session called expectation")
    override func startSession() {
        startSessionCalled.fulfill()
    }


    var disconnectCalled = XCTestExpectation(description: "Disconnect called expectation")
    override func disconnect() {
        disconnectCalled.fulfill()
    }
    
    var handleConnectionErrorCalled = false
    var handleConnectionErrorParam: AssuranceConnectionError?
    override func handleConnectionError(error: AssuranceConnectionError, closeCode: Int) {
        handleConnectionErrorCalled = true
        handleConnectionErrorParam = error
    }

    func mockSocketState(state: SocketState) {
        if let mockSocket = socket as? MockSocket {
            mockSocket.mockSocketState(state: state)
        }
    }
}
