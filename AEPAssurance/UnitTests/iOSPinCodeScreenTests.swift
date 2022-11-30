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

class iOSPinCodeScreenTests: XCTestCase {

    var mockStateManager: AssuranceStateManager!
    var pinCodeScreen: iOSPinCodeScreen!
    let mockUIService = MockUIService()
    let mockMessage = MockFullScreenMessage()
    var mockSessionOrchestrator: MockSessionOrchestrator!
    let mockDataStore = MockDataStore()
    let runtime = TestableExtensionRuntime()
    let mockWebView = MockWebView()

    override func setUp() {
        ServiceProvider.shared.uiService = mockUIService
        mockUIService.fullscreenMessage = mockMessage
        ServiceProvider.shared.namedKeyValueService = mockDataStore
        mockStateManager = AssuranceStateManager(runtime)
        mockSessionOrchestrator = MockSessionOrchestrator(stateManager: mockStateManager)
        pinCodeScreen = iOSPinCodeScreen.init(withPresentationDelegate: mockSessionOrchestrator)
        pinCodeScreen.fullscreenWebView = mockWebView

        // mock the orgID in configuration
        let config = [AssuranceConstants.EventDataKey.CONFIG_ORG_ID: "mockorg@adobe.com"]
        runtime.simulateSharedState(extensionName: AssuranceConstants.SharedStateName.CONFIGURATION, event: nil, data: (config as [String: Any], .set))
    }

    override func tearDown() {
        runtime.reset()
    }

    /*--------------------------------------------------
     show
     --------------------------------------------------*/
    func test_iOSPinCodeScreen_show() throws {
        // setup
        pinCodeScreen.show()

        // verify that the fullscreen message is displayed
        XCTAssertTrue(mockUIService.createFullscreenMessageCalled)
        XCTAssertTrue(mockMessage.showCalled)
    }

    /*--------------------------------------------------
     Simulate connect clicked
     --------------------------------------------------*/
    func test_iOSPinCodeScreen_connectClicked() throws {
        // setup
        pinCodeScreen.show()

        // test
        let shouldURLBeHandled = pinCodeScreen.overrideUrlLoad(message: mockMessage, url: "adbinapp://confirm?code=4444")

        // verify
        XCTAssertTrue(mockSessionOrchestrator.pinScreenConnectClickedCalled)
        XCTAssertEqual("4444", mockSessionOrchestrator.pinScreenConnectClickedPinParameter)
        XCTAssertFalse(shouldURLBeHandled)
    }

    /*--------------------------------------------------
     Simulate connect clicked - when no invalidPinCode
     --------------------------------------------------*/
    func test_iOSPinCodeScreen_connectClicked_invalidPinCode() throws {
        // setup
        pinCodeScreen.show()

        // test
        let shouldURLBeHandled = pinCodeScreen.overrideUrlLoad(message: mockMessage, url: "adbinapp://confirm?nodata")
        
        // verify
        XCTAssertTrue(mockSessionOrchestrator.pinScreenConnectClickedCalled)
        XCTAssertEqual("", mockSessionOrchestrator.pinScreenConnectClickedPinParameter)
        XCTAssertFalse(shouldURLBeHandled)

    }

    /*--------------------------------------------------
     Simulate cancel clicked
     --------------------------------------------------*/
    func test_iOSPinCodeScreen_cancelClicked() throws {
        // test
        let shouldURLBeHandled = pinCodeScreen.overrideUrlLoad(message: mockMessage, url: "adbinapp://cancel?")

        // verify that the message is dismissed
        XCTAssertTrue(mockSessionOrchestrator.pinScreenCancelClickedCalled)
        XCTAssertFalse(shouldURLBeHandled)
    }

    /*--------------------------------------------------
     Simulate random URL clicked in PinPadHTML (highly Improbable)
     --------------------------------------------------*/
    func test_iOSPinCodeScreen_randomLinkClicked() throws {
        // test
        let shouldURLBeHandled = pinCodeScreen.overrideUrlLoad(message: mockMessage, url: "randomURL")

        // verify
        XCTAssertTrue(shouldURLBeHandled)
    }

    /*--------------------------------------------------
     connectionInitialized
     --------------------------------------------------*/
    func test_iOSPinCodeScreen_onSessionInitialized() throws {
        // test
        pinCodeScreen.sessionConnecting()

        // verify that the fullscreen message is displayed
        XCTAssertEqual("showLoading();", mockWebView.javaScriptStringReceived)
    }

    /*--------------------------------------------------
     connectionSucceeded
     --------------------------------------------------*/
    func test_iOSPinCodeScreen_onSessionConnected() throws {
        // setup
        pinCodeScreen.fullscreenMessage = mockMessage

        // test
        pinCodeScreen.sessionConnected()

        // verify that the fullscreen message is dismissed
        XCTAssertTrue(mockMessage.dismissCalled)
    }

    func test_iOSPinCodeScreen_onSessionDisconnected() throws {
        // setup
        pinCodeScreen.fullscreenMessage = mockMessage

        // test
        pinCodeScreen.sessionDisconnected()

        // verify that the fullscreen message is dismissed
        XCTAssertTrue(mockMessage.dismissCalled)
    }

    /*--------------------------------------------------
     onShowFailure
     --------------------------------------------------*/
    func test_onShowFailure() throws {
        // test
        XCTAssertNoThrow(pinCodeScreen.onShowFailure())
    }

    /*--------------------------------------------------
     onShow
     --------------------------------------------------*/
    func test_onShow() throws {
        // setup
        pinCodeScreen.displayed = false

        // test
        pinCodeScreen.onShow(message: mockMessage)

        // verify
        XCTAssertTrue(pinCodeScreen.displayed)
    }

    /*--------------------------------------------------
     onDismiss
     --------------------------------------------------*/
    func test_onDismiss() throws {
        // setup
        pinCodeScreen.fullscreenWebView = mockWebView
        pinCodeScreen.fullscreenMessage = mockMessage
        pinCodeScreen.displayed = true

        // test
        pinCodeScreen.onDismiss(message: mockMessage)

        // verify
        XCTAssertFalse(pinCodeScreen.displayed)
        XCTAssertNil(pinCodeScreen.fullscreenMessage)
        XCTAssertNil(pinCodeScreen.fullscreenWebView)
    }

    /*--------------------------------------------------
     connectionFailedWithError
     --------------------------------------------------*/

    func test_connectionFailedWithError() throws {
        // test
        pinCodeScreen.sessionConnectionFailed(withError: .clientError)

        // verify
        XCTAssertEqual("showError('Client Disconnected','This client has been disconnected due to an unexpected error. Error Code 4400.', 0);",
                       mockWebView.javaScriptStringReceived)
    }

}
