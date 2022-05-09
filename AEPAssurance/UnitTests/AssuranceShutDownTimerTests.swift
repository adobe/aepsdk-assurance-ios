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
    var mockSessionOrchestrator: MockSessionOrchestrator!
    var assurance: Assurance!
    var mockStateManager: MockStateManager!

    override func setUp() {
        ServiceProvider.shared.namedKeyValueService = mockDataStore
        mockStateManager = MockStateManager(runtime)
        mockSessionOrchestrator = MockSessionOrchestrator(stateManager: mockStateManager)
        assurance = Assurance(runtime: runtime)
        assurance.shutdownTime = TimeInterval(1)
        assurance.sessionOrchestrator = mockSessionOrchestrator
    }

    override func tearDown() {
        runtime.reset()
    }

    /*--------------------------------------------------
     shutdown timer tests
     --------------------------------------------------*/

    func test_shutDownTimer() {
        // setup properties
        mockStateManager.connectedWebSocketURL = nil

        // test
        assurance.onRegistered()

        // wait for assurance to shut down
        sleep(3)

        // verify assurance is shutdown after timer
        XCTAssertTrue(mockSessionOrchestrator.terminateSessionCalled)
    }

    func test_shutDownTimer_invalidated_whenSessionStarted() {
        // setup properties
        mockStateManager.connectedWebSocketURL = nil

        // test
        assurance.onRegistered()
        runtime.simulateComingEvent(event: assuranceStartEvent)

        // wait for assurance shutdown timer to run out
        sleep(2)

        // verify shutdown timer is invalidated and terminate session is not called
        XCTAssertFalse(mockSessionOrchestrator.terminateSessionCalled)
    }

    func test_shutDownTimer_invalidedIfAssuranceReconnecting() {
        // setup properties
        mockStateManager.connectedWebSocketURL = "wss://connect.griffon.adobe.com/client/v1?sessionId=4af99a7f-f900-4558-8394-09f665e1b8ae&token=8706&orgId=972C898555E9F7BC7F000101@AdobeOrg&clientId=05222CA5-2763-436C-8F69-DB4CA89F6E8B"

        // test
        assurance.onRegistered()
        sleep(2)

        // verify
        XCTAssertFalse(mockSessionOrchestrator.terminateSessionCalled)
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
