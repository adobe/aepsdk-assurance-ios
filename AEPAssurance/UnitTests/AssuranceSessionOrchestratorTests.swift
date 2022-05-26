/*
 Copyright 2022 Adobe. All rights reserved.
 This file is licensed to you under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License. You may obtain a copy
 of the License at http:www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing, software distributed under
 the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR REPRESENTATIONS
 OF ANY KIND, either express or implied. See the License for the specific language
 governing permissions and limitations under the License.
 */

import Foundation
import XCTest
@testable import AEPAssurance

class AssuranceSessionOrchestratorTests: XCTestCase {
    
    var sessionOrchestrator: AssuranceSessionOrchestrator!
    var mockStateManager: MockStateManager!
    var mockSession: MockSession!
    var mockPresentation: MockPresentation!
    let sampleSessionDetail = AssuranceSessionDetails(sessionId: "mockSessionId", clientId: "mockClientId")
        
    override func setUp(){
        mockStateManager = MockStateManager(TestableExtensionRuntime())
        sessionOrchestrator = AssuranceSessionOrchestrator(stateManager: mockStateManager)
        mockPresentation = MockPresentation(sessionOrchestrator: sessionOrchestrator)
        mockSession = MockSession(sessionDetails: sampleSessionDetail, stateManager: mockStateManager, sessionOrchestrator: sessionOrchestrator, outboundEvents: nil)
        mockSession.presentation = mockPresentation
    }
    
    func test_init() {
        // verify outboundBuffer is initialized
        XCTAssertNotNil(sessionOrchestrator.outboundEventBuffer)
        
        // verify session is nil and still SDK events can be processed
        XCTAssertNil(sessionOrchestrator.session)
        XCTAssertTrue(sessionOrchestrator.canProcessSDKEvents())
    }
    
    
    func test_createSession() {
        // setup
        queueTwoOutboundEvents()
        
        // test
        sessionOrchestrator.createSession(withDetails: sampleSessionDetail)
        
        // verify that a new session is created
        sleep(1)
        XCTAssertNotNil(sessionOrchestrator.session)
        XCTAssertIdentical(sampleSessionDetail, sessionOrchestrator.session?.sessionDetails)
        
        // verify that queued outboundEventBuffer are sent to session and cleared
        XCTAssertEqual(2, sessionOrchestrator.session?.outboundQueue.size())
        XCTAssertNil(sessionOrchestrator.outboundEventBuffer)
    }
        
    func test_createSession_whenSessionAlreadyExists() {
        // setup
        sessionOrchestrator.session = mockSession
         
        // test
        let newSessionDetails = AssuranceSessionDetails(sessionId: "newSessionId", clientId: "newClientId")
        sessionOrchestrator.createSession(withDetails: newSessionDetails)

        // verify that a new session is not created
        XCTAssertIdentical(mockSession, sessionOrchestrator.session)
    }

    func test_terminateSession() {
        // setup
        sessionOrchestrator.session = mockSession
        queueTwoOutboundEvents()

        // test
        sessionOrchestrator.terminateSession()

        // verify
        wait(for: [mockSession.disconnectCalled], timeout: 2.0)
        XCTAssertTrue(sessionOrchestrator.hasEverTerminated)
        XCTAssertTrue(mockStateManager.clearAssuranceStateCalled)
        XCTAssertNil(sessionOrchestrator.outboundEventBuffer)
        XCTAssertNil(sessionOrchestrator.session)
    }

    func test_queueEvent_whenSessionActive() {
        // setup
        sessionOrchestrator.session = mockSession

        // test
        sessionOrchestrator.queueEvent(AssuranceEvent(type: "event1", payload: [:]))

        // verify
        wait(for: [mockSession.sendEventCalled], timeout: 2.0)
        XCTAssertTrue(sessionOrchestrator.outboundEventBuffer!.isEmpty)
    }

    func test_queueEvent_whenSessionInActive() {
        // setup
        sessionOrchestrator.session = nil
        // Invert the expectation as we need to verify sendEvent is not called
        mockSession.sendEventCalled.isInverted = true

        // test
        sessionOrchestrator.queueEvent(AssuranceEvent(type: "event1", payload: [:]))

        // verify
        wait(for: [mockSession.sendEventCalled], timeout: 1.0)
        XCTAssertEqual(1,sessionOrchestrator.outboundEventBuffer!.count)
    }

    func test_queueEvent_whenShutDown() {
        // setup
        sessionOrchestrator.session = nil
        sessionOrchestrator.outboundEventBuffer = nil
        // Invert the expectation as we need to verify sendEvent is not called
        mockSession.sendEventCalled.isInverted = true

        // test
        sessionOrchestrator.queueEvent(AssuranceEvent(type: "event1", payload: [:]))

        // verify
        wait(for: [mockSession.sendEventCalled], timeout: 1.0)
        XCTAssertNil(sessionOrchestrator.outboundEventBuffer)
    }

    func test_pinScreenConnectClicked() {
        // setup
        mockStateManager.orgIDReturnValue = "mockOrgId"
        sessionOrchestrator.session = mockSession

        // test
        sessionOrchestrator.pinScreenConnectClicked("3325")

        // verify
        wait(for: [mockSession.startSessionCalled], timeout: 1.0)
    }


    func test_pinScreenConnectClicked_whenSessionNil() {
        // setup
        // ideally this scenario should never happen
        sessionOrchestrator.session = nil

        // test and verify that orchestrator handles this gracefully
        XCTAssertNoThrow(sessionOrchestrator.pinScreenConnectClicked("3325"))
    }

    func test_pinScreenConnectClicked_whenEmptyPin() {
        // setup
        mockStateManager.orgIDReturnValue = "mockOrgId"
        sessionOrchestrator.session = mockSession
        // Invert the expectation as we need to verify startSession is not called
        mockSession.startSessionCalled.isInverted = true

        // test
        sessionOrchestrator.pinScreenConnectClicked("")

        // verify that the UI is indicated for the error and session is cleared
        wait(for: [mockSession.startSessionCalled], timeout: 1.0)
        wait(for: [mockSession.disconnectCalled], timeout: 1.0)
        XCTAssertTrue(mockPresentation.sessionConnectionErrorCalled)
        XCTAssertEqual(.noPincode ,mockPresentation.sessionConnectionErrorValue)
        XCTAssertTrue(mockStateManager.clearAssuranceStateCalled)
    }

    func test_pinScreenConnectClicked_whenNoOrgId() {
        // setup
        mockStateManager.orgIDReturnValue = nil
        sessionOrchestrator.session = mockSession
        // Invert the expectation as we need to verify startSession is not called
        mockSession.startSessionCalled.isInverted = true

        // test
        sessionOrchestrator.pinScreenConnectClicked("4442")

        // verify that the UI is indicated for the error and session is cleared
        wait(for: [mockSession.startSessionCalled], timeout: 1.0)
        wait(for: [mockSession.disconnectCalled], timeout: 1.0)
        XCTAssertTrue(mockPresentation.sessionConnectionErrorCalled)
        XCTAssertEqual(.noOrgId ,mockPresentation.sessionConnectionErrorValue)
        XCTAssertTrue(mockStateManager.clearAssuranceStateCalled)
    }

    func test_pinScreenCancelClicked() {
        sessionOrchestrator.session = mockSession

        // test
        sessionOrchestrator.pinScreenCancelClicked()

        // verify that the session is terminated and cleared
        XCTAssertTrue(sessionOrchestrator.hasEverTerminated)
        XCTAssertTrue(mockStateManager.clearAssuranceStateCalled)
        wait(for: [mockSession.disconnectCalled], timeout: 1.0)
        XCTAssertNil(sessionOrchestrator.outboundEventBuffer)
        XCTAssertNil(sessionOrchestrator.session)
    }

    func test_disconnectClicked() {
        sessionOrchestrator.session = mockSession

        // test
        sessionOrchestrator.disconnectClicked()

        // verify that the session is terminated and cleared
        XCTAssertTrue(sessionOrchestrator.hasEverTerminated)
        XCTAssertTrue(mockStateManager.clearAssuranceStateCalled)
        wait(for: [mockSession.disconnectCalled], timeout: 1.0)
        XCTAssertNil(sessionOrchestrator.outboundEventBuffer)
        XCTAssertNil(sessionOrchestrator.session)
    }

    private func queueTwoOutboundEvents() {
        sessionOrchestrator.outboundEventBuffer?.append(AssuranceEvent(type: "event1", payload: [:]))
        sessionOrchestrator.outboundEventBuffer?.append(AssuranceEvent(type: "event2", payload: [:]))
    }
    
}
