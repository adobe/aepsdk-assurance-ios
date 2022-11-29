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
    var mockSession: MockSession!
    var mockStateManager: MockStateManager!
    var mockSessionOrchestrator: MockSessionOrchestrator!

    // mock UIServices
    let mockUIService = MockUIService()
    let mockFullScreen = MockFullScreenMessage()
    let mockButton = MockFloatingButton()
    let mockWebView = MockWebView()

    override func setUp() {
        let runtime = TestableExtensionRuntime()
        mockStateManager = MockStateManager(runtime)
        mockSessionOrchestrator = MockSessionOrchestrator(stateManager: mockStateManager)
        let sessionDetail = AssuranceSessionDetails(sessionId: "mocksessionId", clientId: "clientId", environment: .dev)
        mockSession = MockSession(sessionDetails: sessionDetail, stateManager: mockStateManager!, sessionOrchestrator: mockSessionOrchestrator, outboundEvents: nil)
        ServiceProvider.shared.uiService = mockUIService
        statusUI = iOSStatusUI.init(presentationDelegate: mockSessionOrchestrator)

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
        XCTAssertEqual(.topRight, mockButton.initialPositionValue)
    }

    func test_display_multipleTimes() throws {
        // test
        statusUI.display()
        statusUI.display()

        // verify that the floating button is showed only once
        XCTAssertEqual(1, mockButton.showCallCount)
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
     Tests for interactions with StatusUI FullScreen
     --------------------------------------------------*/
    func test_statusUI_fullScreenCancelClicked() throws {
        // setup
        statusUI.display()

        // mock the click of cancel button
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

        // mock the click of disconnect button
        let shouldHandleURL = statusUI.overrideUrlLoad(message: mockFullScreen, url: "adbinapp://disconnect")

        // verify when floating button is tapped, floating button is dismissed
        // and fullscreen status screen is shown
        XCTAssertTrue(mockFullScreen.dismissCalled)
        XCTAssertTrue(mockSessionOrchestrator.disconnectClickedCalled)
        XCTAssertFalse(shouldHandleURL) // assert false because the URL is handled by the delegate method
    }

    func test_statusUI_RandomLinkClicked() throws {
        // setup
        statusUI.display()

        // mock the touch of cancel button
        let shouldHandleURL = statusUI.overrideUrlLoad(message: mockFullScreen, url: "www.randomlink.com")

        // verify when floating button is tapped, floating button is dismissed
        // and fullscreen status screen is shown
        XCTAssertTrue(shouldHandleURL) // assert false because the URL is handled by the delegate method
    }

    /*--------------------------------------------------
     Tests for client logging
     --------------------------------------------------*/
    func test_statusUI_PublishesClientLogs() throws {
        // setup
        mockWebView.expectation = XCTestExpectation(description: "Should call javascript method.")
        let logMessage = "sampleMessage"
        statusUI.display()

        // test
        statusUI.addClientLog(logMessage, visibility: .high)

        // verify
        wait(for: [mockWebView.expectation!], timeout: 2.0)
        XCTAssertEqual(String(format: "addLog(\"%d\", \"%@\");", AssuranceClientLogVisibility.high.rawValue, logMessage), mockWebView.javaScriptStringReceived)
    }

    func test_statusUI_QueuesLogs() throws {
        // setup
        statusUI.webView = nil
        mockWebView.expectation = XCTestExpectation(description: "Should call javascript method.")
        mockWebView.expectationCounter = 3

        // client logs should be queued until webView is loaded
        statusUI.addClientLog("message1", visibility: .high)
        statusUI.addClientLog("message2", visibility: .low)
        statusUI.addClientLog("message3", visibility: .critical)
        statusUI.webView = mockWebView
        statusUI.webViewDidFinishInitialLoading(webView: mockWebView)

        // verify
        wait(for: [mockWebView.expectation!], timeout: 2.0)
        XCTAssertEqual(3, mockWebView.javaScriptMethodInvokeCount)
    }

    func test_updateLogUI_whenNoLogsQueued() throws {
        // setup
        statusUI.clientLogQueue.clear()

        // test
        XCTAssertNoThrow(statusUI.updateLogUI())
    }

    func test_updateLogUI_whenJavaScriptError() throws {
        // setup
        mockWebView.throwJavascriptError = true
        statusUI.display()

        // test
        XCTAssertNoThrow(statusUI.addClientLog("logmessage", visibility: .high))
    }

    /*--------------------------------------------------
     Tests for Floating Button image
     --------------------------------------------------*/
    func test_updateForSocketConnected() throws {
        // setup
        statusUI.display()

        // test
        statusUI.updateForSocketConnected()

        // verify the
        XCTAssertTrue(mockButton.setButtonImageCalled)
        XCTAssertEqual(Data(bytes: ActiveIcon.content, count: ActiveIcon.content.count), mockButton.buttonImageValue)

    }

    func test_updateForSocketInactive() throws {
        // setup
        statusUI.display()

        // test
        statusUI.updateForSocketInActive()

        // verify the
        XCTAssertTrue(mockButton.setButtonImageCalled)
        XCTAssertEqual(Data(bytes: InactiveIcon.content, count: InactiveIcon.content.count), mockButton.buttonImageValue)
    }

    func test_floatingButtonShow_whenSocketConnected() throws {
        // setup
        statusUI.display()
        mockSessionOrchestrator.session = mockSession
        mockSession.mockSocketState(state: .open)

        // test
        statusUI.onShow() // onShow is a Floating button delegate method

        // verify that the Active Icon is set
        XCTAssertTrue(mockButton.setButtonImageCalled)
        XCTAssertEqual(Data(bytes: ActiveIcon.content, count: ActiveIcon.content.count), mockButton.buttonImageValue)
    }

    func test_floatingButtonShow_whenSocketNotConnected() throws {
        // setup
        statusUI.display()
        mockSession.mockSocketState(state: .closed)

        // test
        statusUI.onShow() // onShow is a Floating button delegate method

        // verify that the Active Icon is set
        XCTAssertTrue(mockButton.setButtonImageCalled)
        XCTAssertEqual(Data(bytes: InactiveIcon.content, count: InactiveIcon.content.count), mockButton.buttonImageValue)
    }

    /*--------------------------------------------------
     Tests unused protocol methods
     --------------------------------------------------*/
    func test_UnusedProtocolMethod() throws {
        // Floating button delegate
        XCTAssertNoThrow(statusUI.onDismiss())
        XCTAssertNoThrow(statusUI.onPanDetected())

        // FullScreen delegate
        XCTAssertNoThrow(statusUI.onDismiss(message: mockFullScreen))
        XCTAssertNoThrow(statusUI.onShow(message: mockFullScreen))
        XCTAssertNoThrow(statusUI.onShowFailure())
    }
}
