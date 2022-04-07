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
import os
import XCTest

class PluginLogForwardingTests: XCTestCase {

    var plugin = PluginLogForwarder()
    let runtime = TestableExtensionRuntime()
    var stateManager: MockAssuranceStateManager?
    var mockSession: MockAssuranceSession!

    override func setUpWithError() throws {
        stateManager = MockAssuranceStateManager(runtime)
        stateManager?.environment = .dev
        stateManager?.sessionId = "mocksessionId"
        mockSession = MockAssuranceSession(stateManager!)
    }

    func test_vendor() {
        XCTAssertEqual(AssuranceConstants.Vendor.MOBILE, plugin.vendor)
    }

    func test_commandType() {
        XCTAssertEqual(AssuranceConstants.CommandType.LOG_FORWARDING, plugin.commandType)
    }

    func test_commandLogForward_whenSessionNotAvailable() {
        plugin.session = nil
        let data = """
                    {
                      "eventID": "someID", "vendor": "someVendor", "timestamp": 113435556 ,
                      "type": "control",
                      "payload": {
                        "type": "logForwarding",
                        "detail": {
                         "enable" : true
                        }
                      }
                    }
                   """.data(using: .utf8)!

        // test
        plugin.receiveEvent(AssuranceEvent.from(jsonData: data)!)

        // verify
        XCTAssertFalse(plugin.currentlyRunning)

    }

    func test_commandLogForward_emptyPayload() {
        // setup
        plugin.onRegistered(mockSession)
        let data = """
                    {
                      "eventID": "someID", "vendor": "someVendor", "timestamp": 113435556 ,
                      "type": "control",
                      "payload": {
                      }
                    }
                   """.data(using: .utf8)!

        // test
        plugin.receiveEvent(AssuranceEvent.from(jsonData: data)!)

        // verify
        XCTAssertFalse(plugin.currentlyRunning)

    }

    func test_commandLogForward_emptyDetails() {
        // setup
        plugin.onRegistered(mockSession)
        let data = """
                    {
                      "eventID": "someID", "vendor": "someVendor", "timestamp": 113435556 ,
                      "type": "control",
                      "payload": {
                        "type": "logForwarding",
                        "detail": {
                        }
                      }
                    }
                   """.data(using: .utf8)!

        // test
        plugin.receiveEvent(AssuranceEvent.from(jsonData: data)!)

        // verify
        XCTAssertFalse(plugin.currentlyRunning)
    }

    func test_commandLogForward_enableKeyNotBoolean() {
        // setup
        plugin.onRegistered(mockSession)
        let data = """
                    {
                      "eventID": "someID", "vendor": "someVendor", "timestamp": 113435556 ,
                      "type": "control",
                      "payload": {
                        "type": "logForwarding",
                        "detail": {
                         "enable" : "InvalidValue"
                        }
                      }
                    }
                   """.data(using: .utf8)!

        // test
        plugin.receiveEvent(AssuranceEvent.from(jsonData: data)!)

        // verify
        XCTAssertFalse(plugin.currentlyRunning)
    }

    func test_commandLogForwarding_completeWorkflow() {
        // setup
        mockSession.expectation = XCTestExpectation(description: "Sends log event to connected session.")
        plugin.onRegistered(mockSession)

        // test
        plugin.receiveEvent(logForwardingEvent(start: true))
        sleep(1)
        XCTAssertTrue(plugin.currentlyRunning)

        // add a log statement
        os_log("secret log message")

        // verify
        wait(for: [mockSession.expectation!], timeout: 2.0)
        XCTAssertTrue(mockSession.sendEventCalled)
        let logEvent = mockSession.sentEvent
        XCTAssertEqual(AssuranceConstants.EventType.LOG, logEvent?.type)
        XCTAssertEqual(AssuranceConstants.Vendor.MOBILE, logEvent?.vendor)
        let logMessage = logEvent?.payload?["logline"]?.stringValue
        XCTAssertNotNil(logMessage)
        XCTAssertTrue(logMessage!.contains("secret log message"))

        sleep(1)
        mockSession.sendEventCalled = false

        // now send event to stop forwarding
        plugin.receiveEvent(logForwardingEvent(start: false))

        // add log statement
        os_log("another secret log message")

        // verify
        XCTAssertFalse(plugin.currentlyRunning)
        XCTAssertFalse(mockSession.sendEventCalled)
    }

    func test_commandLogForwarding_stopForwarding_whenNeverStarted() {
        // setup
        plugin.onRegistered(mockSession)

        // test
        plugin.receiveEvent(logForwardingEvent(start: false))

        // verify
        XCTAssertFalse(plugin.currentlyRunning)
    }

    func test_commandLogForwarding_when_startForwardingReceivedTwice() {
        // setup
        mockSession.expectation = XCTestExpectation(description: "Sends log event to connected session.")
        plugin.onRegistered(mockSession)

        // test
        plugin.receiveEvent(logForwardingEvent(start: true))
        plugin.receiveEvent(logForwardingEvent(start: true))

        // verify
        os_log("secret log message")
        wait(for: [mockSession.expectation!], timeout: 2.0)
        XCTAssertTrue(mockSession.sendEventCalled)
    }

    func test_unusedProtocolMethod() {
        XCTAssertNoThrow(plugin.onSessionConnected())
        XCTAssertNoThrow(plugin.onSessionTerminated())
        XCTAssertNoThrow(plugin.onSessionDisconnectedWithCloseCode(-1))
    }

    private func logForwardingEvent(start: Bool) -> AssuranceEvent {
        let data = """
                    {
                      "eventID": "someID", "vendor": "someVendor", "timestamp": 113435556 ,
                      "type": "control",
                      "payload": {
                        "type": "logForwarding",
                        "detail": {
                         "enable" : \(start)
                        }
                      }
                    }
                   """.data(using: .utf8)!

        return AssuranceEvent.from(jsonData: data)!
    }

}
