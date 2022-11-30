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
    let sampleSessionDetail = AssuranceSessionDetails(sessionId: "mockSessionId", clientId: "mockClientId")
    var mockQuickConnectManager: MockQuickConnectManager!
        
    override func setUp(){
        mockStateManager = MockStateManager(TestableExtensionRuntime())
        sessionOrchestrator = AssuranceSessionOrchestrator(stateManager: mockStateManager)
        mockSession = MockSession(sessionDetails: sampleSessionDetail, stateManager: mockStateManager, sessionOrchestrator: sessionOrchestrator, outboundEvents: nil)
        mockQuickConnectManager = MockQuickConnectManager(stateManager: mockStateManager, uiDelegate: sessionOrchestrator)
        sessionOrchestrator.quickConnectManager = mockQuickConnectManager
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
        XCTAssertTrue(sessionOrchestrator.hasEverTerminated)
        XCTAssertTrue(mockStateManager.clearAssuranceStateCalled)
        XCTAssertTrue(mockSession.disconnectCalled)
        XCTAssertNil(sessionOrchestrator.outboundEventBuffer)
        XCTAssertNil(sessionOrchestrator.session)
    }
    
    func test_queueEvent_whenSessionActive() {
        // setup
        sessionOrchestrator.session = mockSession
        
        // test
        sessionOrchestrator.queueEvent(AssuranceEvent(type: "event1", payload: [:]))
        
        // verify
        XCTAssertTrue(sessionOrchestrator.outboundEventBuffer!.isEmpty)
        XCTAssertTrue(mockSession.sendEventCalled)
    }
    
    func test_queueEvent_whenSessionInActive() {
        // setup
        sessionOrchestrator.session = nil
        
        // test
        sessionOrchestrator.queueEvent(AssuranceEvent(type: "event1", payload: [:]))
        
        // verify
        XCTAssertFalse(mockSession.sendEventCalled)
        XCTAssertEqual(1,sessionOrchestrator.outboundEventBuffer!.count)        
    }
    
    func test_queueEvent_whenShutDown() {
        // setup
        sessionOrchestrator.session = nil
        sessionOrchestrator.outboundEventBuffer = nil
        
        // test
        sessionOrchestrator.queueEvent(AssuranceEvent(type: "event1", payload: [:]))
        
        // verify
        XCTAssertFalse(mockSession.sendEventCalled)
        XCTAssertNil(sessionOrchestrator.outboundEventBuffer)
    }
    
    // MARK: - AssurancePresentationDelegate PinCode tests
    
    func test_pinScreenConnectClicked() {
        // setup
        mockStateManager.orgIDReturnValue = "mockOrgId"
        sessionOrchestrator.session = mockSession
                
        // test
        sessionOrchestrator.pinScreenConnectClicked("3325")
        
        // verify
        XCTAssertTrue(mockSession.startSessionCalled)
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
        let mockAuthorizingPresentation = MockAuthorizingPresentation(authorizingView: MockSessionAuthorizingUI(withPresentationDelegate: sessionOrchestrator))
        sessionOrchestrator.authorizingPresentation = mockAuthorizingPresentation
        mockStateManager.orgIDReturnValue = "mockOrgId"
        sessionOrchestrator.session = mockSession
                
        // test
        sessionOrchestrator.pinScreenConnectClicked("")
        
        // verify that the UI is indicated for the error and session is cleared
        XCTAssertFalse(mockSession.startSessionCalled)
        XCTAssertTrue(mockSession.disconnectCalled)
        XCTAssertTrue(mockAuthorizingPresentation.sessionConnectionErrorCalled)
        XCTAssertEqual(.noPincode ,mockAuthorizingPresentation.sessionConnectionErrorValue)
        XCTAssertTrue(mockStateManager.clearAssuranceStateCalled)
    }
    
    func test_pinScreenConnectClicked_whenNoOrgId() {
        // setup
        let mockAuthorizingPresentation = MockAuthorizingPresentation(authorizingView: MockSessionAuthorizingUI(withPresentationDelegate: sessionOrchestrator))
        sessionOrchestrator.authorizingPresentation = mockAuthorizingPresentation
        mockStateManager.orgIDReturnValue = nil
        sessionOrchestrator.session = mockSession
                
        // test
        sessionOrchestrator.pinScreenConnectClicked("4442")
        
        // verify that the UI is indicated for the error and session is cleared
        XCTAssertFalse(mockSession.startSessionCalled)
        XCTAssertTrue(mockSession.disconnectCalled)
        XCTAssertTrue(mockAuthorizingPresentation.sessionConnectionErrorCalled)
        XCTAssertEqual(.noOrgId ,mockAuthorizingPresentation.sessionConnectionErrorValue)
        XCTAssertTrue(mockStateManager.clearAssuranceStateCalled)
    }
    
    func test_pinScreenCancelClicked() {
        sessionOrchestrator.session = mockSession
                
        // test
        sessionOrchestrator.pinScreenCancelClicked()
        
        // verify that the session is terminated and cleared
        XCTAssertTrue(sessionOrchestrator.hasEverTerminated)
        XCTAssertTrue(mockStateManager.clearAssuranceStateCalled)
        XCTAssertTrue(mockSession.disconnectCalled)
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
        XCTAssertTrue(mockSession.disconnectCalled)
        XCTAssertNil(sessionOrchestrator.outboundEventBuffer)
        XCTAssertNil(sessionOrchestrator.session)
    }
    
    // MARK: - AssurancePresentationDelegate QuickConnect tests
    
    func test_quickConnectBegin() {
        sessionOrchestrator.quickConnectBegin()
        
        XCTAssertTrue(mockQuickConnectManager.createDeviceCalled)
    }
    
    func test_connectCancelled() {
        sessionOrchestrator.quickConnectCancelled()
        
        XCTAssertTrue(mockQuickConnectManager.cancelRetryGetDeviceStatusCalled)
    }
    
    func test_createQuickConnectSession_withoutSession() {
        let mockAuthorizingPresentation = MockAuthorizingPresentation(authorizingView: MockSessionAuthorizingUI(withPresentationDelegate: sessionOrchestrator))
        sessionOrchestrator.authorizingPresentation = mockAuthorizingPresentation
        let sampleSessionID = "sampleSessionID"
        let sampleSessionDetails = AssuranceSessionDetails(sessionId: sampleSessionID, clientId: "sampleClientID")
        sessionOrchestrator.createQuickConnectSession(with: sampleSessionDetails)
        
        XCTAssertTrue(mockAuthorizingPresentation.sessionConnectingCalled)
        
        XCTAssertTrue(mockStateManager.shareAssuranceStateCalled)
        XCTAssertEqual(sampleSessionID, mockStateManager.shareAssuranceStateSessionID)
        XCTAssertNotNil(sessionOrchestrator.session)
        XCTAssertNil(sessionOrchestrator.outboundEventBuffer)
    }
    
    func test_createQuickConnectSession_withExistingSession() {
        let mockAuthorizingPresentation = MockAuthorizingPresentation(authorizingView: MockSessionAuthorizingUI(withPresentationDelegate: sessionOrchestrator))
        sessionOrchestrator.authorizingPresentation = mockAuthorizingPresentation
        let sampleSessionID = "sampleSessionID"
        let sampleSessionDetails = AssuranceSessionDetails(sessionId: sampleSessionID, clientId: "sampleClientID")
        let session = AssuranceSession(sessionDetails: sampleSessionDetails, stateManager: mockStateManager, sessionOrchestrator: sessionOrchestrator, outboundEvents: nil)
        sessionOrchestrator.session = session
        sessionOrchestrator.createQuickConnectSession(with: sampleSessionDetails)
        
        XCTAssertFalse(mockAuthorizingPresentation.sessionConnectingCalled)
        
        XCTAssertFalse(mockStateManager.shareAssuranceStateCalled)
        XCTAssertNotNil(sessionOrchestrator.session)
        XCTAssertNotNil(sessionOrchestrator.outboundEventBuffer)
    }
    
    func test_quickConnectError() {
        let sampleSessionID = "sampleSessionID"
        let sampleSessionDetails = AssuranceSessionDetails(sessionId: sampleSessionID, clientId: "sampleClientID")
        
        let mockSession = MockSession(sessionDetails: sampleSessionDetails, stateManager: mockStateManager, sessionOrchestrator: sessionOrchestrator, outboundEvents: nil)
        sessionOrchestrator.session = mockSession
        sessionOrchestrator.quickConnectError(error: .genericError)
        
        XCTAssertTrue(mockSession.handleConnectionErrorCalled)
        XCTAssertEqual(mockSession.handleConnectionErrorParam, .genericError)
    }
    
    // MARK: - AssuranceConnectionDelegate tests
    func test_handleConnectionError() {
        let mockAuthorizingPresentation = MockAuthorizingPresentation(authorizingView: MockSessionAuthorizingUI(withPresentationDelegate: sessionOrchestrator))
        sessionOrchestrator.authorizingPresentation = mockAuthorizingPresentation
        
        sessionOrchestrator.handleConnectionError(error: .genericError)
        
        XCTAssertTrue(mockAuthorizingPresentation.sessionConnectionErrorCalled)
        XCTAssertEqual(mockAuthorizingPresentation.sessionConnectionErrorValue, .genericError)
        
    }
    
    func test_handleSuccessfulConnection() {
        let mockAuthorizingPresentation = MockAuthorizingPresentation(authorizingView: MockSessionAuthorizingUI(withPresentationDelegate: sessionOrchestrator))
        sessionOrchestrator.authorizingPresentation = mockAuthorizingPresentation
        
        sessionOrchestrator.handleSuccessfulConnection()
        
        XCTAssertTrue(mockAuthorizingPresentation.sessionConnectedCalled)
        
    }
    
    func test_handleSessionDisconnect() {
        let mockAuthorizingPresentation = MockAuthorizingPresentation(authorizingView: MockSessionAuthorizingUI(withPresentationDelegate: sessionOrchestrator))
        sessionOrchestrator.authorizingPresentation = mockAuthorizingPresentation
        
        sessionOrchestrator.handleSessionDisconnect()
        
        XCTAssertTrue(mockAuthorizingPresentation.sessionDisconnectedCalled)
    }
    
    // MARK: - Private methods
    private func queueTwoOutboundEvents() {
        sessionOrchestrator.outboundEventBuffer?.append(AssuranceEvent(type: "event1", payload: [:]))
        sessionOrchestrator.outboundEventBuffer?.append(AssuranceEvent(type: "event2", payload: [:]))
    }
    
}
