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

class MockSocket: SocketConnectable {
    var expectation: XCTestExpectation?
    var socketURL: URL?
    var delegate: SocketDelegate
    var socketState: SocketState
    var eventChunker: EventChunker = MockEventChunker()

    required init(withDelegate delegate: SocketDelegate) {
        self.delegate = delegate
        self.socketState = .closed
    }

    var connectCalled = false
    var connectURL: URL?
    func connect(withUrl url: URL) {
        expectation?.fulfill()
        connectCalled = true
        connectURL = url
    }

    var disconnectCalled = false
    func disconnect() {
        disconnectCalled = true
    }

    var sendEventCalled = false
    var sentEvent: AssuranceEvent?
    func sendEvent(_ event: AssuranceEvent) {
        expectation?.fulfill()
        sendEventCalled = true
        sentEvent = event
    }

    func mockSocketState(state: SocketState) {
        self.socketState = state
    }
}

class MockEventChunker: EventChunker {
    
    var chunkCalled = false
    var chunkedEventsToReturn: [AssuranceEvent] = []
    func chunk(_ event: AEPAssurance.AssuranceEvent) -> [AEPAssurance.AssuranceEvent] {
        chunkCalled = true
        return chunkedEventsToReturn
    }
    
    var stitchCalled = false
    var eventToReturn: AssuranceEvent? = nil
    func stitch(_ chunkedEvents: [AEPAssurance.AssuranceEvent]) -> AEPAssurance.AssuranceEvent? {
        stitchCalled = true
        return eventToReturn
    }
    
    
}
