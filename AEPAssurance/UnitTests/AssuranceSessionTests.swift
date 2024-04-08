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
    
    let AUTHENTICATED_SOCKET_URL = "wss://connect.griffon.adobe.com/client/v1?sessionId=sampleSessionId&token=8706&orgId=sample@AdobeOrg&clientId=sampleClientId"

    let runtime = TestableExtensionRuntime()
    var session: AssuranceSession!
    var stateManager: MockStateManager!
    var sessionDetails: AssuranceSessionDetails!
    var mockSocket: MockSocket!
    var mockStatusPresentation: MockStatusPresentation!
    var sessionOrchestrator: MockSessionOrchestrator!
    let mockUIService = MockUIService()
    let mockMessagePresentable = MockFullscreenMessagePresentable()
    let mockPlugin = PluginTaco()
    var mockStatusUI: MockStatusUI!

    override func setUpWithError() throws {
        // create the required mocks
        ServiceProvider.shared.uiService = mockUIService
        mockUIService.fullscreenMessage = mockMessagePresentable
        stateManager = MockStateManager(runtime)
        sessionOrchestrator = MockSessionOrchestrator(stateManager: stateManager)
        mockStatusUI = MockStatusUI(presentationDelegate: sessionOrchestrator)
        mockStatusPresentation = MockStatusPresentation(with: mockStatusUI)
        try initNonAuthenticatedSession()
    }
    
    override func tearDown() {
        mockSocket = nil
        session = nil
        stateManager = nil
        mockStatusPresentation = nil
    }


    func test_startSession_whenSessionDetailsNotAuthenticated() throws {
        // setup is already initialized with non authenticated session
        
        // test
        session.startSession()

        // verify the presentation layer is called to invoke the pinCode screen
        XCTAssertTrue(sessionOrchestrator.initializePinScreenFlowCalled)
        XCTAssertFalse(mockSocket.connectCalled)
    }
    
    func test_startSession_whenSessionDetailsAuthenticated() throws {
        // setup
        try initAuthenticatedSession()

        // test
        session.startSession()

        // verify 
        XCTAssertTrue(mockSocket.connectCalled)
        XCTAssertEqual(AUTHENTICATED_SOCKET_URL, mockSocket.connectURL?.absoluteString)
    }

    func test_startSession_whenAlreadyConnected() throws {
        // setup
        mockSocket.socketState = .open

        // test
        session.startSession()

        // verify
        XCTAssertFalse(mockUIService.createFullscreenMessageCalled)
        XCTAssertFalse(mockSocket.connectCalled)
    }

    func test_session_RegistersPlugins() throws {
        // setup
        try initNonAuthenticatedSession()
        
        // verify that 4 internal plugins are registered
        XCTAssertEqual(4, session.pluginHub.pluginCollection[AssuranceConstants.Vendor.MOBILE.hash]?.count)
    }

    func test_session_queuesOutBoundEvents() throws {
        // test
        session.sendEvent(sampleAssuranceEvent())
        session.sendEvent(sampleAssuranceEvent())

        XCTAssertEqual(2, session.outboundQueue.size())
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
        XCTAssertTrue(mockStatusPresentation.sessionConnectedCalled)
        XCTAssertTrue(mockPlugin.isSessionConnectedCalled)
    }

    func test_session_receives_startForwardingEvent_sessionWasOnceTerminated() throws {
        // setup
        sessionOrchestrator.hasEverTerminated = true
        stateManager.expectation = XCTestExpectation(description: "Calls extension to get the shared state events")

        // test
        session.webSocket(mockSocket, didReceiveEvent: startForwardingEvent)

        // verify
        wait(for: [stateManager.expectation!], timeout: 2.0)
        XCTAssertTrue(stateManager.getAllExtensionStateDataCalled)
    }
    
    func test_session_receives_chunkedEvents() {
        let mockEventChunker = MockEventChunker()
        mockSocket.eventChunker = mockEventChunker
        mockEventChunker.eventToReturn = tacoEvent
        session.pluginHub.registerPlugin(mockPlugin, toSession: session)
        mockPlugin.expectation = XCTestExpectation(description: "sends inbound event to respective plugin")
        let chunkEvent1 = AssuranceEvent(type: "control",
                                         payload: ["type":"Test"],
                                         metadata: [AssuranceConstants.AssuranceEvent.MetadataKey.CHUNK_ID: "testChunkID",
                                                    AssuranceConstants.AssuranceEvent.MetadataKey.CHUNK_SEQUENCE: 1,
                                                    AssuranceConstants.AssuranceEvent.MetadataKey.CHUNK_TOTAL: 3])
        
        let chunkEvent2 = AssuranceEvent(type: "control",
                                         payload: ["type":"Test"],
                                         metadata: [AssuranceConstants.AssuranceEvent.MetadataKey.CHUNK_ID: "testChunkID",
                                                    AssuranceConstants.AssuranceEvent.MetadataKey.CHUNK_SEQUENCE: 2,
                                                    AssuranceConstants.AssuranceEvent.MetadataKey.CHUNK_TOTAL: 3])
        
        let chunkEvent3 = AssuranceEvent(type: "control",
                                         payload: ["type":"Test"],
                                         metadata: [AssuranceConstants.AssuranceEvent.MetadataKey.CHUNK_ID: "testChunkID",
                                                    AssuranceConstants.AssuranceEvent.MetadataKey.CHUNK_SEQUENCE: 3,
                                                    AssuranceConstants.AssuranceEvent.MetadataKey.CHUNK_TOTAL: 3])
        
        session.webSocket(mockSocket, didReceiveEvent: chunkEvent1)
        session.webSocket(mockSocket, didReceiveEvent: chunkEvent2)
        session.webSocket(mockSocket, didReceiveEvent: chunkEvent3)
        
        wait(for: [mockPlugin.expectation!], timeout: 2.0)
        XCTAssertTrue(mockPlugin.eventReceived)
        XCTAssertTrue(mockEventChunker.stitchCalled)
        XCTAssertEqual(0, session.inboundQueue.size())
    }
    
    func test_session_receives_chunkedEvent_stitchFails() {
        let mockEventChunker = MockEventChunker()
        mockSocket.eventChunker = mockEventChunker
        session.pluginHub.registerPlugin(mockPlugin, toSession: session)
        mockPlugin.expectation = XCTestExpectation(description: "sends inbound event to respective plugin")
        mockPlugin.expectation?.isInverted = true
        let chunkEvent1 = AssuranceEvent(type: "control",
                                         payload: ["type":"Test"],
                                         metadata: [AssuranceConstants.AssuranceEvent.MetadataKey.CHUNK_ID: "testChunkID",
                                                    AssuranceConstants.AssuranceEvent.MetadataKey.CHUNK_SEQUENCE: 1,
                                                    AssuranceConstants.AssuranceEvent.MetadataKey.CHUNK_TOTAL: 3])
        
        let chunkEvent2 = AssuranceEvent(type: "control",
                                         payload: ["type":"Test"],
                                         metadata: [AssuranceConstants.AssuranceEvent.MetadataKey.CHUNK_ID: "testChunkID",
                                                    AssuranceConstants.AssuranceEvent.MetadataKey.CHUNK_SEQUENCE: 2,
                                                    AssuranceConstants.AssuranceEvent.MetadataKey.CHUNK_TOTAL: 3])
        
        let chunkEvent3 = AssuranceEvent(type: "control",
                                         payload: ["type":"Test"],
                                         metadata: [AssuranceConstants.AssuranceEvent.MetadataKey.CHUNK_ID: "testChunkID",
                                                    AssuranceConstants.AssuranceEvent.MetadataKey.CHUNK_SEQUENCE: 3,
                                                    AssuranceConstants.AssuranceEvent.MetadataKey.CHUNK_TOTAL: 3])
        
        session.webSocket(mockSocket, didReceiveEvent: chunkEvent1)
        session.webSocket(mockSocket, didReceiveEvent: chunkEvent2)
        session.webSocket(mockSocket, didReceiveEvent: chunkEvent3)
        
        wait(for: [mockPlugin.expectation!], timeout: 2.0)
        XCTAssertFalse(mockPlugin.eventReceived)
        XCTAssertTrue(mockEventChunker.stitchCalled)
        XCTAssertEqual(0, session.inboundQueue.size())
    }


    func test_session_disconnect() throws {
        // setup
        session.pluginHub.registerPlugin(mockPlugin, toSession: session)
        session.canStartForwarding = true

        // test
        session.disconnect()

        // verify
        XCTAssertTrue(mockPlugin.isSessionTerminatedCalled)
        XCTAssertTrue(mockSocket.disconnectCalled)
        XCTAssertFalse(session.canStartForwarding)
        XCTAssertNil(stateManager.connectedWebSocketURL)
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
        XCTAssertTrue(mockStatusPresentation.addClientLogCalled)
        XCTAssertTrue(mockStatusPresentation.sessionDisconnectedCalled)
        XCTAssertTrue(sessionOrchestrator.handleSessionDisconnectCalled)
        XCTAssertTrue(mockPlugin.isSessionDisconnectCalled)
    }

    func test_session_whenSocketDisconnect_OrgMismatch() throws {
        // setup
        session.pluginHub.registerPlugin(mockPlugin, toSession: session)

        // test
        session.webSocketDidDisconnect(mockSocket, AssuranceConstants.SocketCloseCode.ORG_MISMATCH, "", true)

        // verify
        XCTAssertTrue(mockStatusPresentation.addClientLogCalled)
        XCTAssertTrue(sessionOrchestrator.handleConnectionErrorCalled)
        XCTAssertEqual(sessionOrchestrator.handleConnectionErrorParam, AssuranceConnectionError.orgIDMismatch)
        XCTAssertFalse(session.canStartForwarding)
        XCTAssertNil(stateManager.connectedWebSocketURL)
    }

    func test_session_socketDisconnect_ConnectionLimit() throws {
        // test
        session.webSocketDidDisconnect(mockSocket, AssuranceConstants.SocketCloseCode.CONNECTION_LIMIT, "", true)

        // verify
        XCTAssertTrue(mockStatusPresentation.addClientLogCalled)
        XCTAssertTrue(sessionOrchestrator.handleConnectionErrorCalled)
        XCTAssertEqual(sessionOrchestrator.handleConnectionErrorParam, AssuranceConnectionError.connectionLimit)
    }

    func test_session_socketDisconnect_EventLimit() throws {
        // test
        session.webSocketDidDisconnect(mockSocket, AssuranceConstants.SocketCloseCode.EVENTS_LIMIT, "", true)

        // verify
        XCTAssertTrue(mockStatusPresentation.addClientLogCalled)
        XCTAssertTrue(sessionOrchestrator.handleConnectionErrorCalled)
        XCTAssertEqual(sessionOrchestrator.handleConnectionErrorParam, AssuranceConnectionError.eventLimit)
    }

    func test_session_socketDisconnect_ClientError() throws {
        // test
        session.webSocketDidDisconnect(mockSocket, AssuranceConstants.SocketCloseCode.CLIENT_ERROR, "", true)

        // verify
        XCTAssertTrue(mockStatusPresentation.addClientLogCalled)
        XCTAssertTrue(sessionOrchestrator.handleConnectionErrorCalled)
        XCTAssertEqual(sessionOrchestrator.handleConnectionErrorParam, AssuranceConnectionError.clientError)
    }


    func test_session_socketDisconnect_DeletedSession() throws {
        // test
        session.webSocketDidDisconnect(mockSocket, AssuranceConstants.SocketCloseCode.DELETED_SESSION, "", true)

        // verify
        XCTAssertTrue(mockStatusPresentation.addClientLogCalled)
        XCTAssertTrue(sessionOrchestrator.handleConnectionErrorCalled)
        XCTAssertEqual(sessionOrchestrator.handleConnectionErrorParam, AssuranceConnectionError.deletedSession)
    }


    func test_session_socketDisconnect_AbnormalClosure_thenReconnects() throws {
        // setup
        try initAuthenticatedSession()
        stateManager.setConnectedURLString("someConnectedURLString")
        mockSocket.expectation = XCTestExpectation(description: "Attempts to reconnect")

        // test
        session.webSocketDidDisconnect(mockSocket, AssuranceConstants.SocketCloseCode.ABNORMAL_CLOSURE, "", true)

        // verify the the session attempts to reconnect
        wait(for: [mockSocket.expectation!], timeout: 2.0)
        XCTAssertTrue(mockStatusPresentation.addClientLogCalled)
        XCTAssertTrue(mockStatusPresentation.sessionReconnectingCalled)
        XCTAssertTrue(session.isAttemptingToReconnect)
        XCTAssertFalse(session.canStartForwarding)
        XCTAssertTrue(mockSocket.connectCalled)
        XCTAssertEqual(AUTHENTICATED_SOCKET_URL, mockSocket.connectURL?.absoluteString)
    }
    
    func test_session_socketDisconnect_AbnormalClosure_whenNotConnected_showsError() throws {
        // setup
        try initAuthenticatedSession()
        stateManager.setConnectedURLString(nil)

        // test
        session.webSocketDidDisconnect(mockSocket, AssuranceConstants.SocketCloseCode.ABNORMAL_CLOSURE, "", true)

        // verify
        XCTAssertTrue(mockStatusPresentation.addClientLogCalled)
        XCTAssertTrue(sessionOrchestrator.handleConnectionErrorCalled)
        XCTAssertEqual(.genericError, sessionOrchestrator.handleConnectionErrorParam)
        XCTAssertTrue(mockStatusPresentation.sessionConnectionErrorCalled)
        XCTAssertFalse(session.isAttemptingToReconnect)
        XCTAssertEqual(.genericError, mockStatusPresentation.sessionConnectionErrorValue)
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

    private func initAuthenticatedSession() throws {
        sessionDetails = try AssuranceSessionDetails(withURLString: AUTHENTICATED_SOCKET_URL)
        session = AssuranceSession(sessionDetails: sessionDetails, stateManager: stateManager, sessionOrchestrator: sessionOrchestrator, outboundEvents: nil)
        
        // initiate the properties
        mockSocket = MockSocket(withDelegate: session)
        session.socket = mockSocket
        session.statusPresentation = mockStatusPresentation
    }
    
    
    private func initNonAuthenticatedSession() throws {
        sessionDetails = AssuranceSessionDetails(sessionId: "mockSessionId", clientId: "mockClientId", environment: .prod)
        session = AssuranceSession(sessionDetails: sessionDetails, stateManager: stateManager, sessionOrchestrator: sessionOrchestrator, outboundEvents: nil)
        
        // initiate the properties
        mockSocket = MockSocket(withDelegate: session)
        session.socket = mockSocket
        session.statusPresentation = mockStatusPresentation
    }
    
}
