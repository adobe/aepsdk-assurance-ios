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
    var stateManager: MockAssuranceStateManager!
    var mockSocket: MockSocket!
    var mockPresentation: MockPresentation!
    var sessionOrchestrator: AssuranceSessionOrchestrator!
    let mockUIService = MockUIService()
    let mockMessagePresentable = MockFullscreenMessagePresentable()
    let mockPlugin = PluginTaco()

    override func setUp() {
        ServiceProvider.shared.uiService = mockUIService
        mockUIService.fullscreenMessage = mockMessagePresentable
        stateManager = MockAssuranceStateManager(runtime)
        sessionOrchestrator = AssuranceSessionOrchestrator(stateManager: stateManager)
        mockPresentation = MockPresentation(stateManager: stateManager, sessionOrchestrator:sessionOrchestrator)
        session = AssuranceSession(stateManager, sessionOrchestrator, mockPresentation)
        mockSocket = MockSocket(withDelegate: session)
        session.socket = mockSocket
        
    }

    override func tearDown() {
    }

    func test_startSession() throws {
        // setup
        stateManager.connectedWebSocketURL = nil

        // test
        session.startSession()

        // verify
        XCTAssertTrue(mockUIService.createFullscreenMessageCalled)
        XCTAssertTrue(mockMessagePresentable.showCalled)
    }

    func test_startSession_whenAlreadyConnected() throws {
        // setup
        mockSocket.socketState = .open

        // test
        session.startSession()

        // verify
        XCTAssertFalse(mockUIService.createFullscreenMessageCalled)
    }

    func test_startSession_whenConnectionURLExist() throws {
        // setup
        stateManager.connectedWebSocketURL = "wss://socket/connection"

        // test
        session.startSession()

        // verify
        XCTAssertTrue(mockSocket.connectCalled)
        XCTAssertEqual("wss://socket/connection", mockSocket.connectURL?.absoluteString)
    }

    func test_session_RegistersPlugins() throws {
        // verify that 3 internal plugins are registered
        XCTAssertEqual(4, session.pluginHub.pluginCollection[AssuranceConstants.Vendor.MOBILE.hash]?.count)
    }

    func test_assuranceSession_queuesOutBoundEvents() throws {
        // test
        session.sendEvent(sampleAssuranceEvent())
        session.sendEvent(sampleAssuranceEvent())

        XCTAssertEqual(2, session.outboundQueue.size())
    }

    func test_session_shutDownSession() throws {
        // setup
        session.outboundQueue.enqueue(newElement: sampleAssuranceEvent())
        session.inboundQueue.enqueue(newElement: sampleAssuranceEvent())
        XCTAssertEqual(1, session.outboundQueue.size())
        XCTAssertEqual(1, session.inboundQueue.size())

        // test
        session.shutDownSession()

        // verify
        XCTAssertEqual(0, session.outboundQueue.size())
        XCTAssertEqual(0, session.inboundQueue.size())
        XCTAssertTrue(session.didClearBootEvent)
        XCTAssertFalse(session.canProcessSDKEvents)
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

    func test_session_receives_startForwardingEvent() throws {
        // setup
        session.pluginHub.registerPlugin(mockPlugin, toSession: session)
        mockPlugin.expectation = XCTestExpectation(description: "Calls SessionConnected delegate method on plugin")

        // test
        session.webSocket(mockSocket, didReceiveEvent: startForwardingEvent)

        // verify
        wait(for: [mockPlugin.expectation!], timeout: 1.0)
        XCTAssertTrue(session.canStartForwarding)
        XCTAssertTrue(mockPresentation.sessionConnectedCalled)
        XCTAssertTrue(mockPlugin.isSessionConnectedCalled)
    }

    func test_session_receives_startForwardingEvent_AfterBootEventsAreCleared() throws {
        // setup
        session.didClearBootEvent = true
        stateManager.expectation = XCTestExpectation(description: "Calls extension to get the shared state events")

        // test
        session.webSocket(mockSocket, didReceiveEvent: startForwardingEvent)

        // verify
        wait(for: [stateManager.expectation!], timeout: 2.0)
        XCTAssertTrue(stateManager.getAllExtensionStateDataCalled)
    }


    func test_session_terminateSession() throws {
        // setup
        session.pluginHub.registerPlugin(mockPlugin, toSession: session)
        stateManager.sessionId = "mockSessionID"
        stateManager.connectedWebSocketURL = "mockConnectedSocketURL"
        stateManager.environment = AssuranceEnvironment.prod
        session.canStartForwarding = true

        // test
        session.terminateSession()

        // verify
        XCTAssertTrue(mockPlugin.isSessionTerminatedCalled)
        XCTAssertTrue(mockSocket.disconnectCalled)
        XCTAssertFalse(session.canStartForwarding)
        XCTAssertFalse(session.canProcessSDKEvents)
        XCTAssertNil(stateManager.sessionId)
        XCTAssertNil(stateManager.connectedWebSocketURL)
        XCTAssertEqual(AssuranceConstants.DEFAULT_ENVIRONMENT, stateManager.environment)
    }

    func test_session_whenConnected_sendsClientInfoEvent() throws {
        // test
        session.webSocketDidConnect(mockSocket)

        // verify
        XCTAssertTrue(mockSocket.sendEventCalled)
        XCTAssertEqual(AssuranceConstants.EventType.CLIENT, mockSocket.sentEvent?.type)
    }

    func test_session_whenWebSocketOnError() throws {
        // test
        XCTAssertNoThrow(session.webSocketOnError(mockSocket))
    }

    func test_session_whenSocketStateOpen_savesWebSocketURL() throws {
        // setup
        let sampleURL = URL(string: "https://adobe.com")
        mockSocket.socketURL = sampleURL

        // test
        session.webSocket(mockSocket, didChangeState: .open)

        // verify
        XCTAssertEqual(sampleURL?.absoluteString, stateManager.connectedWebSocketURL)
    }

    func test_session_whenSocketDisconnect_NormalClosure() throws {
        // setup
        session.pluginHub.registerPlugin(mockPlugin, toSession: session)

        // test
        session.webSocketDidDisconnect(mockSocket, AssuranceConstants.SocketCloseCode.NORMAL_CLOSURE, "Normal Closure", true)

        // verify
        XCTAssertTrue(mockPresentation.sessionDisconnectedCalled)
        XCTAssertTrue(mockPlugin.isSessionDisconnectCalled)
    }

    func test_session_whenSocketDisconnect_OrgMismatch() throws {
        // setup
        session.pluginHub.registerPlugin(mockPlugin, toSession: session)
        stateManager.sessionId = "sampleSessionID"
        stateManager.connectedWebSocketURL = "url://with/sampleSessionID"

        // test
        session.webSocketDidDisconnect(mockSocket, AssuranceConstants.SocketCloseCode.ORG_MISMATCH, "", true)

        // verify
        XCTAssertTrue(mockPresentation.sessionConnectionErrorCalled)
        XCTAssertEqual(mockPresentation.sessionConnectionErrorValue, AssuranceConnectionError.orgIDMismatch)
        XCTAssertFalse(session.canStartForwarding)
        XCTAssertNil(stateManager.sessionId)
        XCTAssertNil(stateManager.connectedWebSocketURL)
        XCTAssertEqual(AssuranceConstants.DEFAULT_ENVIRONMENT, stateManager.environment)
    }

    func test_session_whenSocketDisconnect_ConnectionLimit() throws {
        // test
        session.webSocketDidDisconnect(mockSocket, AssuranceConstants.SocketCloseCode.CONNECTION_LIMIT, "", true)

        // verify
        XCTAssertTrue(mockPresentation.sessionConnectionErrorCalled)
        XCTAssertEqual(mockPresentation.sessionConnectionErrorValue, AssuranceConnectionError.connectionLimit)
    }

    func test_session_whenSocketDisconnect_EventLimit() throws {
        // test
        session.webSocketDidDisconnect(mockSocket, AssuranceConstants.SocketCloseCode.EVENTS_LIMIT, "", true)

        // verify
        XCTAssertTrue(mockPresentation.sessionConnectionErrorCalled)
        XCTAssertEqual(mockPresentation.sessionConnectionErrorValue, AssuranceConnectionError.eventLimit)
    }

    func test_session_whenSocketDisconnect_ClientError() throws {
        // test
        session.webSocketDidDisconnect(mockSocket, AssuranceConstants.SocketCloseCode.CLIENT_ERROR, "", true)

        // verify
        XCTAssertTrue(mockPresentation.sessionConnectionErrorCalled)
        XCTAssertEqual(mockPresentation.sessionConnectionErrorValue, AssuranceConnectionError.clientError)
    }


    func test_session_whenSocketDisconnect_DeletedSession() throws {
        // test
        session.webSocketDidDisconnect(mockSocket, AssuranceConstants.SocketCloseCode.DELETED_SESSION, "", true)

        // verify
        XCTAssertTrue(mockPresentation.sessionConnectionErrorCalled)
        XCTAssertEqual(mockPresentation.sessionConnectionErrorValue, AssuranceConnectionError.deletedSession)
    }


    func test_session_whenSocketDisconnect_AbnormalClosure() throws {
        // setup
        let sampleSocketURL = "wss://socketURL"
        mockSocket.expectation = XCTestExpectation(description: "Attempts to reconnect")
        stateManager.connectedWebSocketURL = sampleSocketURL

        // test
        session.webSocketDidDisconnect(mockSocket, AssuranceConstants.SocketCloseCode.ABNORMAL_CLOSURE, "", true)

        // verify
        XCTAssertTrue(mockPresentation.sessionReconnectingCalled)
        wait(for: [mockSocket.expectation!], timeout: 2.0)
        XCTAssertTrue(session.isAttemptingToReconnect)
        XCTAssertFalse(session.canStartForwarding)
        XCTAssertTrue(mockSocket.connectCalled)
        XCTAssertEqual(sampleSocketURL, mockSocket.connectURL?.absoluteString)
    }

    private func sampleAssuranceEvent() -> AssuranceEvent {
        return AssuranceEvent(type: "sampleType", payload: nil)
    }

    private var tacoEvent: AssuranceEvent {
        return AssuranceEvent(type: "control", payload: ["type": "Taco"], vendor: "Food")
    }

    private var startForwardingEvent: AssuranceEvent {
        return AssuranceEvent(type: "control", payload: ["type": AnyCodable.init(AssuranceConstants.CommandType.START_EVENT_FORWARDING)], vendor: AssuranceConstants.Vendor.MOBILE)
    }

}
