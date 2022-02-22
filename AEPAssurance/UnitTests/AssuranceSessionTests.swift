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
    var assuranceExtension: MockAssurance!
    var mockSocket: MockSocket!
    var mockStatusUI: MockStatusUI!
    var mockPinPad: MockPinPad!
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
        mockPinPad = MockPinPad(withExtension: assuranceExtension)
    }

    override func tearDown() {
    }

    func test_startSession() throws {
        // setup
        assuranceExtension.connectedWebSocketURL = nil

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
        assuranceExtension.connectedWebSocketURL = "wss://socket/connection"

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
        session.statusUI = mockStatusUI
        mockPlugin.expectation = XCTestExpectation(description: "Calls SessionConnected delegate method on plugin")

        // test
        session.webSocket(mockSocket, didReceiveEvent: startForwardingEvent)

        // verify
        wait(for: [mockPlugin.expectation!], timeout: 1.0)
        XCTAssertTrue(session.canStartForwarding)
        XCTAssertTrue(mockStatusUI.displayCalled)
        XCTAssertTrue(mockStatusUI.updateForSocketConnectedCalled)
        XCTAssertTrue(mockPlugin.isSessionConnectedCalled)
    }

    func test_session_receives_startForwardingEvent_AfterBootEventsAreCleared() throws {
        // setup
        session.didClearBootEvent = true
        assuranceExtension.expectation = XCTestExpectation(description: "Calls extension to get the shared state events")

        // test
        session.webSocket(mockSocket, didReceiveEvent: startForwardingEvent)

        // verify
        wait(for: [assuranceExtension.expectation!], timeout: 2.0)
        XCTAssertTrue(assuranceExtension.getAllExtensionStateDataCalled)
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
        XCTAssertFalse(session.canProcessSDKEvents)
        XCTAssertNil(assuranceExtension.sessionId)
        XCTAssertNil(assuranceExtension.connectedWebSocketURL)
        XCTAssertEqual(AssuranceConstants.DEFAULT_ENVIRONMENT, assuranceExtension.environment)
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
        XCTAssertEqual(sampleURL?.absoluteString, assuranceExtension.connectedWebSocketURL)
    }

    func test_session_whenSocketDisconnect_NormalClosure() throws {
        // setup
        session.pluginHub.registerPlugin(mockPlugin, toSession: session)
        session.statusUI = mockStatusUI
        session.pinCodeScreen = mockPinPad

        // test
        session.webSocketDidDisconnect(mockSocket, AssuranceConstants.SocketCloseCode.NORMAL_CLOSURE, "Normal Closure", true)

        // verify
        XCTAssertTrue(mockStatusUI.removeCalled)
        XCTAssertTrue(mockPlugin.isSessionDisconnectCalled)
        XCTAssertTrue(mockPinPad.connectionFinishedCalled)
    }

    func test_session_whenSocketDisconnect_OrgMismatch() throws {
        // setup
        session.pluginHub.registerPlugin(mockPlugin, toSession: session)
        session.statusUI = mockStatusUI
        mockPinPad.isDisplayed = true
        session.pinCodeScreen = mockPinPad
        assuranceExtension.sessionId = "sampleSessionID"
        assuranceExtension.connectedWebSocketURL = "url://with/sampleSessionID"

        // test
        session.webSocketDidDisconnect(mockSocket, AssuranceConstants.SocketCloseCode.ORG_MISMATCH, "", true)

        // verify
        XCTAssertTrue(mockStatusUI.removeCalled)
        XCTAssertTrue(mockPinPad.connectionFailedWithErrorCalled)
        XCTAssertEqual(AssuranceConnectionError.orgIDMismatch, mockPinPad.connectionFailedWithErrorValue)
        XCTAssertFalse(session.canStartForwarding)
        XCTAssertNil(assuranceExtension.sessionId)
        XCTAssertNil(assuranceExtension.connectedWebSocketURL)
        XCTAssertEqual(AssuranceConstants.DEFAULT_ENVIRONMENT, assuranceExtension.environment)
    }

    func test_session_whenSocketDisconnect_ConnectionLimit() throws {
        // setup
        session.statusUI = mockStatusUI
        mockPinPad.isDisplayed = true
        session.pinCodeScreen = mockPinPad

        // test
        session.webSocketDidDisconnect(mockSocket, AssuranceConstants.SocketCloseCode.CONNECTION_LIMIT, "", true)

        // verify
        XCTAssertTrue(mockStatusUI.removeCalled)
        XCTAssertTrue(mockPinPad.connectionFailedWithErrorCalled)
        XCTAssertEqual(AssuranceConnectionError.connectionLimit, mockPinPad.connectionFailedWithErrorValue)
    }

    func test_session_whenSocketDisconnect_EventLimit() throws {
        // setup
        session.statusUI = mockStatusUI
        mockPinPad.isDisplayed = true
        session.pinCodeScreen = mockPinPad

        // test
        session.webSocketDidDisconnect(mockSocket, AssuranceConstants.SocketCloseCode.EVENTS_LIMIT, "", true)

        // verify
        XCTAssertTrue(mockStatusUI.removeCalled)
        XCTAssertTrue(mockPinPad.connectionFailedWithErrorCalled)
        XCTAssertEqual(AssuranceConnectionError.eventLimit, mockPinPad.connectionFailedWithErrorValue)
    }

    func test_session_whenSocketDisconnect_ClientError() throws {
        // setup
        session.statusUI = mockStatusUI
        mockPinPad.isDisplayed = true
        session.pinCodeScreen = mockPinPad

        // test
        session.webSocketDidDisconnect(mockSocket, AssuranceConstants.SocketCloseCode.CLIENT_ERROR, "", true)

        // verify
        XCTAssertTrue(mockStatusUI.removeCalled)
        XCTAssertTrue(mockPinPad.connectionFailedWithErrorCalled)
        XCTAssertEqual(AssuranceConnectionError.clientError, mockPinPad.connectionFailedWithErrorValue)
    }
    
    
    func test_session_whenSocketDisconnect_DeletedSession() throws {
        // setup
        session.statusUI = mockStatusUI
        mockPinPad.isDisplayed = true
        session.pinCodeScreen = mockPinPad

        // test
        session.webSocketDidDisconnect(mockSocket, AssuranceConstants.SocketCloseCode.DELETED_SESSION, "", true)

        // verify
        XCTAssertTrue(mockStatusUI.removeCalled)
        XCTAssertTrue(mockPinPad.connectionFailedWithErrorCalled)
        XCTAssertEqual(AssuranceConnectionError.deletedSession, mockPinPad.connectionFailedWithErrorValue)
    }
     

    func test_session_whenSocketDisconnect_AbnormalClosure() throws {
        // setup
        let sampleSocketURL = "wss://socketURL"
        mockSocket.expectation = XCTestExpectation(description: "Attempts to reconnect")
        session.statusUI = mockStatusUI
        mockPinPad.isDisplayed = true
        session.pinCodeScreen = mockPinPad
        assuranceExtension.connectedWebSocketURL = sampleSocketURL

        // test
        session.webSocketDidDisconnect(mockSocket, AssuranceConstants.SocketCloseCode.ABNORMAL_CLOSURE, "", true)

        // verify
        wait(for: [mockSocket.expectation!], timeout: 2.0)
        XCTAssertTrue(session.isAttemptingToReconnect)
        XCTAssertFalse(session.canStartForwarding)
        XCTAssertTrue(mockPinPad.connectionFailedWithErrorCalled)
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
