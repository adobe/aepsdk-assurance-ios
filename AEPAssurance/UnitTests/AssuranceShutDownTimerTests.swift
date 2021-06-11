/*
 Copyright 2021 Adobe. All rights reserved.
 This file is licensed to you under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License. You may obtain a copy
 of the License at http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing, software distributed under
 the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR REPRESENTATIONS
 OF ANY KIND, either express or implied. See the License for the specific language
 governing permissions and limitations under the License.
 */

@testable import AEPAssurance
@testable import AEPCore
@testable import AEPServices
import Foundation
import XCTest

class AssuranceShutDownTimerTests: XCTestCase {

    let runtime = TestableExtensionRuntime()
    let mockDataStore = MockDataStore()
    var mockSession: MockAssuranceSession!
    var assurance: Assurance!

    override func setUp() {
        ServiceProvider.shared.namedKeyValueService = mockDataStore
        assurance = Assurance(runtime: runtime, shutdownTime: 1)

        // mock the interaction with AssuranceSession class
        mockSession = MockAssuranceSession(assurance)
        assurance.assuranceSession = mockSession
    }

    override func tearDown() {
        runtime.reset()
    }

    /*--------------------------------------------------
     shutdown timer tests
     --------------------------------------------------*/

    func test_shutDownTimer() {
        // setup properties
        assurance.connectedWebSocketURL = nil

        // test
        assurance.onRegistered()

        // verify assurance listens to event before shut down
        XCTAssertTrue(assurance.readyForEvent(testEvent))

        // wait for assurance to shut down
        sleep(2)

        // verify assurance is shutdown after timer
        XCTAssertFalse(assurance.readyForEvent(testEvent))
    }

    func test_shutDownTimer_invalidated_whenSessionStarted() {
        // setup properties
        assurance.connectedWebSocketURL = nil

        // test
        assurance.onRegistered()

        // verify assurance listens to event before shut down
        XCTAssertTrue(assurance.readyForEvent(testEvent))
        runtime.simulateComingEvent(event: assuranceStartEvent)

        // wait for assurance shutdown timer to run out
        sleep(2)

        // verify shutdown timer is invalidated and assurance keeps running
        XCTAssertTrue(assurance.readyForEvent(testEvent))
    }

    func test_shutDownTimer_invalidedIfAssuranceReconnecting() {
        // setup properties
        assurance.connectedWebSocketURL = "wss://sampleSocketURL"

        // test
        assurance.onRegistered()
        sleep(2)

        // verify
        XCTAssertTrue(assurance.readyForEvent(testEvent))
    }

    var assuranceStartEvent: Event {
        return Event(name: "Start Session",
                     type: AssuranceConstants.SDKEventType.ASSURANCE,
                     source: EventSource.requestContent,
                     data: [
                        AssuranceConstants.EventDataKey.START_SESSION_URL: "griffon://?adb_validation_sessionid=28f4a622-d34f-4036-c81a-d21352144b57&env=stage"
                     ])
    }

    var testEvent: Event {
        return Event(name: "testName",
                     type: "testType",
                     source: "testSource",
                     data: nil)
    }
}
