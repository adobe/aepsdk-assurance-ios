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

@testable import AEPAssurance
import Foundation
import XCTest
import AEPServices

class AssuranceStatusPresentationTests: XCTestCase {
    // testing class
    var presentation: AssuranceStatusPresentation!
    
    // mocked dependencies
    let runtime = TestableExtensionRuntime()
    var mockStateManager: MockStateManager!
    var mockSessionOrchestrator: MockSessionOrchestrator!
    var mockStatusUI : MockStatusUI!
        
    override func setUp() {
        mockStateManager = MockStateManager(runtime)
        mockSessionOrchestrator = MockSessionOrchestrator(stateManager: mockStateManager)
        mockStatusUI = MockStatusUI(presentationDelegate: mockSessionOrchestrator)
        presentation = AssuranceStatusPresentation(with: mockStatusUI)
    }
    
    func test_addClientLog() {
        // test
        presentation.addClientLog("testString", visibility: .normal)

        // verify
        XCTAssertTrue(mockStatusUI.addClientLogCalled)
        XCTAssertEqual("testString", mockStatusUI.addClientLogMessage)
        XCTAssertEqual("testString", mockStatusUI.addClientLogMessage)
    }
    
    
    func test_onSessionReconnecting() {
        // test
        presentation.sessionReconnecting()

        // verify that the status screen is display with inactive status
        XCTAssertTrue(mockStatusUI.displayCalled)
        XCTAssertTrue(mockStatusUI.updateForSocketInActiveCalled)
    }
    
    func test_onSessionConnected() {
        // test
        presentation.sessionConnected()
        
        // verify
        XCTAssertTrue(mockStatusUI.displayCalled)
        XCTAssertTrue(mockStatusUI.updateForSocketConnectedCalled)
    }
    
    func test_onSessionDisconnected() {
        // test
        presentation.sessionDisconnected()
        
        // verify
        XCTAssertTrue(mockStatusUI.removeCalled)
    }
    
    func test_onSessionConnectionError_retryable() {
        // test
        presentation.sessionConnectionError(error: .genericError)
        
        // verify
        XCTAssertFalse(mockStatusUI.removeCalled)
    }
    
    func test_onSessionConnectionError_nonRetryable() {
        // test
        presentation.sessionConnectionError(error: .eventLimit)
        
        // verify
        XCTAssertTrue(mockStatusUI.removeCalled)
        
    }
}
