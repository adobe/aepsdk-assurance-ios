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

class AssuranceAuthorizingPresentationTests: XCTestCase {
    
    // testing class
    var presentation: AssuranceAuthorizingPresentation!
    
    // mocked dependencies
    let runtime = TestableExtensionRuntime()
    var mockStateManager: MockStateManager!
    var mockSessionOrchestrator: MockSessionOrchestrator!
    var mockPinPad : MockSessionAuthorizingUI!
        
    override func setUp() {
        mockStateManager = MockStateManager(runtime)
        mockSessionOrchestrator = MockSessionOrchestrator(stateManager: mockStateManager)
        mockPinPad = MockSessionAuthorizingUI(withPresentationDelegate: mockSessionOrchestrator)
        presentation = AssuranceAuthorizingPresentation(authorizingView: mockPinPad)
    }
    
   func test_onShow() {
        let expectation = XCTestExpectation(description: "Show pin pad expectation")
        presentation.show()
        DispatchQueue.main.async {
            expectation.fulfill()
            XCTAssertTrue(self.mockPinPad.showCalled)
        }
        
        self.wait(for: [expectation], timeout: 1)
    }
    
    func test_onSessionConnected() {
        // setup
        mockPinPad.displayed = true
        
        // test
        presentation.sessionConnected()
        
        // verify that the pinpad screen is removed
        XCTAssertTrue(mockPinPad.onSessionConnectedCalled)
    }
    
    
    func test_onSessionDisconnected() {        
        // test
        presentation.sessionDisconnected()

        // verify that the status screen is display with inactive status
        XCTAssertTrue(mockPinPad.onSessionDisconnectedCalled)
    }
    
    func test_onSessionConnectionError_nonRetryable() {
        // setup
        mockPinPad.displayed = true
        
        // test
        presentation.sessionConnectionError(error: .eventLimit)

        // verify
        XCTAssertTrue(mockPinPad.sessionConnectionFailed)
        XCTAssertEqual(.eventLimit, mockPinPad.sessionConnectionFailedError)
    }
    
    func test_onSessionConnectionError_Retryable() {
        // setup
        mockPinPad.displayed = true
        
        // test
        presentation.sessionConnectionError(error: .genericError)

        // verify that the status screen is display with inactive status
        XCTAssertTrue(mockPinPad.sessionConnectionFailed)
        XCTAssertEqual(.genericError, mockPinPad.sessionConnectionFailedError)
        
    }
        
}

