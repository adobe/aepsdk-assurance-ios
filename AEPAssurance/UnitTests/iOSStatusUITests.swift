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
import WebKit
import XCTest

class iOSStatusUITests: XCTestCase {
    
    var statusUI: iOSStatusUI!
    var mockSession: MockAssuranceSession!
    var mockAssuranceExtension: MockAssurance!
    
    // mock UIServices
    let mockUIService = MockUIService()
    let mockFullScreen = MockFullScreenMessage()
    let mockButton = MockFloatingButton()
    let mockWebView = MockWebView()
        
    override func setUp() {
        let runtime = TestableExtensionRuntime()
        mockAssuranceExtension = MockAssurance(runtime: runtime)
        mockSession = MockAssuranceSession(mockAssuranceExtension!)
        
        ServiceProvider.shared.uiService = mockUIService
        statusUI = iOSStatusUI.init(withSession: mockSession)
        
        mockUIService.fullscreenMessage = mockFullScreen
        mockUIService.floatingButton = mockButton
        statusUI.webView = mockWebView
    }
    
    
    /*--------------------------------------------------
     StatusUI display
     --------------------------------------------------*/
    func test_display() throws {
        // test
        statusUI.display()

        // verify that fullscreen and floating button are created
        XCTAssertTrue(mockUIService.createFullscreenMessageCalled)
        XCTAssertTrue(mockUIService.createFloatingButtonCalled)
        
        // verify floating button is displayed at the correct position
        XCTAssertTrue(mockButton.showCalled)
        XCTAssertEqual(.topRight ,mockButton.initialPositionValue)
    }
    
    
    
    /*--------------------------------------------------
     StatusUI remove
     --------------------------------------------------*/
    func test_remove() throws {
        // setup
        statusUI.display()
        
        // test
        statusUI.remove()
        
        // verify floating button is displayed at the correct spot
        XCTAssertTrue(mockButton.dismissCalled)
        XCTAssertNil(statusUI.webView)
        XCTAssertNil(statusUI.floatingButton)
        XCTAssertNil(statusUI.fullScreenMessage)
    }
    
    
    /*--------------------------------------------------
     Floating Button tapped
     --------------------------------------------------*/
    func test_onFloatingButtonTap() throws {
        // setup
        statusUI.display()
        
        // test
        statusUI.onTapDetected()
        
        // verify when floating button is tapped, floating button is dismissed
        // and fullscreen status screen is shown
        XCTAssertTrue(mockButton.dismissCalled)
        XCTAssertTrue(mockFullScreen.showCalled)
    }
    
    /*--------------------------------------------------
     Floating button is redisplayed when fullscreen message is dismissed
     --------------------------------------------------*/
    func test_statusUI_fullScreenCancelClicked() throws {
        // setup
        statusUI.display()
        
        // mock the touch of cancel button
        let shouldHandleURL = statusUI.overrideUrlLoad(message: mockFullScreen, url: "adbinapp://cancel?")
        
        // verify when floating button is tapped, floating button is dismissed
        // and fullscreen status screen is shown
        XCTAssertTrue(mockButton.showCalled)
        XCTAssertTrue(mockFullScreen.hideCalled)
        XCTAssertFalse(shouldHandleURL) // assert false because the URL is handled by the delegate method
    }
    
    func test_statusUI_fullScreenDisconnectClicked() throws {
        // setup
        statusUI.display()
        
        // mock the touch of cancel button
        let shouldHandleURL = statusUI.overrideUrlLoad(message: mockFullScreen, url: "adbinapp://disconnect")
        
        // verify when floating button is tapped, floating button is dismissed
        // and fullscreen status screen is shown
        XCTAssertTrue(mockFullScreen.dismissCalled)
        XCTAssertTrue(mockSession.terminateSessionCalled)
        XCTAssertFalse(shouldHandleURL) // assert false because the URL is handled by the delegate method
    }
    
    
    func test_statusUI_() throws {
        // setup
        statusUI.display()
        
        // mock the touch of cancel button
        let shouldHandleURL = statusUI.overrideUrlLoad(message: mockFullScreen, url: "nohost")
        
        // verify when floating button is tapped, floating button is dismissed
        // and fullscreen status screen is shown
        XCTAssertTrue(shouldHandleURL) // assert false because the URL is handled by the delegate method
    }
    
    
    
    
    
    
}
