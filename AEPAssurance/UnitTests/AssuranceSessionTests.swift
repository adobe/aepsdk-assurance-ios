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

class AssuranceSessionTests: XCTestCase {

    let runtime = TestableExtensionRuntime()
    var session: AssuranceSession!
    var assuranceExtension: Assurance!
    var mockSocket: MockSocket!
    var mockStatusUI: MockStatusUI!
    let mockUIService = MockUIService()
    let mockMessagePresentable = MockFullscreenMessagePresentable()
    let mockPlugin = PluginTaco()

    override func setUp() {
        ServiceProvider.shared.uiService = mockUIService
        mockUIService.fullscreenMessage = mockMessagePresentable
        assuranceExtension = MockAssurance(runtime: runtime)
        session = AssuranceSession(assuranceExtension)
        mockSocket = MockSocket(withDelegate: session)
        mockStatusUI = MockStatusUI(withSession: session)
        session.socket = mockSocket
    }

    override func tearDown() {
    }

    func test_session_RegistersPlugins() throws {
        // verify that 3 internal plugins are registered
        XCTAssertEqual(3, session.pluginHub.pluginCollection[AssuranceConstants.Vendor.MOBILE.hash]?.count)
    }

    func test_assuranceSession_queuesOutBoundEvents() throws {
        // test
        session.sendEvent(sampleAssuranceEvent())
        session.sendEvent(sampleAssuranceEvent())

        XCTAssertEqual(2, session.outboundQueue.size())
    }

    func test_session_clearQueueEvents() throws {
        // setup
        session.outboundQueue.enqueue(newElement: sampleAssuranceEvent())
        session.inboundQueue.enqueue(newElement: sampleAssuranceEvent())
        XCTAssertEqual(1, session.outboundQueue.size())
        XCTAssertEqual(1, session.inboundQueue.size())

        // test
        session.clearQueueEvents()

        // verify
        XCTAssertEqual(0, session.outboundQueue.size())
        XCTAssertEqual(0, session.inboundQueue.size())
        XCTAssertTrue(session.didClearBootEvent)
    }

    func test_session_outBoundEventsAreQueued_until_socketConnected() throws {
        // setup
        mockSocket.socketState = .closed

        // test
        session.sendEvent(sampleAssuranceEvent())

        // verify
        XCTAssertFalse(mockSocket.sendEventCalled)
        XCTAssertEqual(1, session.outboundQueue.size())
    }

    func test_session_outBoundEventsAreQueued_until_startForwardingEventReceived() throws {
        // setup
        mockSocket.socketState = .open
        session.canStartForwarding = false

        // test
        session.sendEvent(sampleAssuranceEvent())

        // verify
        XCTAssertFalse(mockSocket.sendEventCalled)
        XCTAssertEqual(1, session.outboundQueue.size())
    }

    func test_session_outBoundEventsAreSent_after_startForwardingEventReceived() throws {
        // setup
        mockSocket.expectation = XCTestExpectation(description: "sends outbound event to socket")
        mockSocket.socketState = .open
        session.canStartForwarding = true

        // test
        session.sendEvent(sampleAssuranceEvent())

        // verify
        wait(for: [mockSocket.expectation!], timeout: 2.0)
        XCTAssertTrue(mockSocket.sendEventCalled)
        XCTAssertEqual(0, session.outboundQueue.size())
    }

    func test_session_received_nonControlEvent() throws {
        // test
        session.webSocket(mockSocket, didReceiveEvent: sampleAssuranceEvent())

        // verify
        XCTAssertFalse(mockPlugin.eventReceived)
    }

    func test_session_received_randomEvent() throws {
        // test
        session.webSocket(mockSocket, didReceiveEvent: sampleAssuranceEvent())

        // verify the plugins do not receive random event
        XCTAssertFalse(mockPlugin.eventReceived)
    }

    func test_session_received_eventForPluginTaco() throws {
        // setup
        session.pluginHub.registerPlugin(mockPlugin, toSession: session)
        mockPlugin.expectation = XCTestExpectation(description: "sends inbound event to respective plugin")

        // test
        session.webSocket(mockSocket, didReceiveEvent: tacoEvent)

        // verify
        wait(for: [mockPlugin.expectation!], timeout: 2.0)
        XCTAssertTrue(mockPlugin.eventReceived)
        XCTAssertEqual(0, session.inboundQueue.size())
    }

    func test_session_addsClientLogs() throws {
        // setup
        session.statusUI = mockStatusUI

        // test
        session.addClientLog("message", visibility: .high)

        // verify
        XCTAssertTrue(mockStatusUI.addClientLogCalled)
    }

    func test_session_terminateSession() throws {
        // setup
        session.pluginHub.registerPlugin(mockPlugin, toSession: session)
        assuranceExtension.sessionId = "mockSessionID"
        assuranceExtension.connectedWebSocketURL = "mockConnectedSocketURL"
        assuranceExtension.environment = AssuranceEnvironment.prod
        session.canStartForwarding = true

        // test
        session.terminateSession()

        // verify
        XCTAssertTrue(mockPlugin.isSessionTerminatedCalled)
        XCTAssertTrue(mockSocket.disconnectCalled)
        XCTAssertFalse(session.canStartForwarding)
        XCTAssertNil(assuranceExtension.sessionId)
        XCTAssertNil(assuranceExtension.connectedWebSocketURL)
        XCTAssertEqual(AssuranceConstants.DEFAULT_ENVIRONMENT, assuranceExtension.environment)
    }

    private func sampleAssuranceEvent() -> AssuranceEvent {
        return AssuranceEvent(type: "sampleType", payload: nil)
    }

    private func startForwardingEvent() -> AssuranceEvent {
        return AssuranceEvent(type: "sampleType", payload: nil)
    }

    private var tacoEvent: AssuranceEvent {
        return AssuranceEvent(type: "control", payload: ["type": "Taco"], vendor: "Food")
    }

}
