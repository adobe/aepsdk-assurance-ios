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
    let mockDataStore = MockDataStore()
    let runtime = TestableExtensionRuntime()
    let mockWebView = MockWebView()

    override func setUp() {
        ServiceProvider.shared.uiService = mockUIService
        mockUIService.fullscreenMessage = mockMessage
        ServiceProvider.shared.namedKeyValueService = mockDataStore
        mockStateManager = AssuranceStateManager(runtime)
        pinCodeScreen = iOSPinCodeScreen.init(withState: mockStateManager)
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
        pinCodeScreen.show(callback: { _, _ in })

        // verify that the fullscreen message is displayed
        XCTAssertTrue(mockUIService.createFullscreenMessageCalled)
        XCTAssertTrue(mockMessage.showCalled)
    }

    /*--------------------------------------------------
     Simulate connect clicked
     --------------------------------------------------*/
    func test_iOSPinCodeScreen_connectClicked() throws {
        // setup
        mockStateManager.sessionId =  "mockSessionID"

        // verify that the correct socket url is created
        let expectation = XCTestExpectation(description: "Correct webSocket url should be created")
        expectation.assertForOverFulfill = true
        pinCodeScreen.show(callback: { socketURL, _ in

            XCTAssertTrue(socketURL!.absoluteString.contains("wss://connect.griffon.adobe.com/client/v1?sessionId=mockSessionID&token=4444&orgId=mockorg@adobe.com&clientId="))
            expectation.fulfill()
        })

        // test
        let shouldURLBeHandled = pinCodeScreen.overrideUrlLoad(message: mockMessage, url: "adbinapp://confirm?code=4444")

        // verify
        XCTAssertFalse(shouldURLBeHandled)
        wait(for: [expectation], timeout: 1)
    }

    /*--------------------------------------------------
     Simulate connect clicked - when no orgID
     --------------------------------------------------*/
    func test_iOSPinCodeScreen_connectClicked_whenNotConfigured() throws {
        // setup
        mockStateManager.sessionId =  "mockSessionID"
        runtime.simulateSharedState(extensionName: AssuranceConstants.SharedStateName.CONFIGURATION, event: nil, data: (nil, .none))

        // verify
        let expectation = XCTestExpectation(description: "No OrgID error should be returned")
        pinCodeScreen.show(callback: { _, error in
            XCTAssertEqual(error, AssuranceConnectionError.noOrgId)
            expectation.fulfill()
        })

        // test
        _ = pinCodeScreen.overrideUrlLoad(message: mockMessage, url: "adbinapp://confirm?code=4444")
    }

    /*--------------------------------------------------
     Simulate connect clicked - when no invalidPinCode
     --------------------------------------------------*/
    func test_iOSPinCodeScreen_connectClicked_invalidPinCode() throws {
        // setup
        mockStateManager.sessionId =  "mockSessionID"

        // verify
        let expectation = XCTestExpectation(description: "No Pincode error should be returned")
        pinCodeScreen.show(callback: { _, error in
            XCTAssertEqual(error, AssuranceConnectionError.noPincode)
            expectation.fulfill()
        })

        // test
        _ = pinCodeScreen.overrideUrlLoad(message: mockMessage, url: "adbinapp://confirm?nodata")

    }

    /*--------------------------------------------------
     Simulate cancel clicked
     --------------------------------------------------*/
    func test_iOSPinCodeScreen_cancelClicked() throws {
        // test
        let shouldURLBeHandled = pinCodeScreen.overrideUrlLoad(message: mockMessage, url: "adbinapp://cancel?")

        // verify that the message is dismissed
        XCTAssertTrue(mockMessage.dismissCalled)
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
    func test_iOSPinCodeScreen_connectionInitialized() throws {
        // test
        pinCodeScreen.connectionInitialized()

        // verify that the fullscreen message is displayed
        XCTAssertEqual("showLoading();", mockWebView.javaScriptStringReceived)
    }

    /*--------------------------------------------------
     connectionSucceeded
     --------------------------------------------------*/
    func test_iOSPinCodeScreen_connectionSucceeded() throws {
        // setup
        pinCodeScreen.fullscreenMessage = mockMessage

        // test
        pinCodeScreen.connectionSucceeded()

        // verify that the fullscreen message is dismissed
        XCTAssertTrue(mockMessage.dismissCalled)
    }

    func test_iOSPinCodeScreen_connectionFinished() throws {
        // setup
        pinCodeScreen.fullscreenMessage = mockMessage

        // test
        pinCodeScreen.connectionFinished()

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
        pinCodeScreen.isDisplayed = false

        // test
        pinCodeScreen.onShow(message: mockMessage)

        // verify
        XCTAssertTrue(pinCodeScreen.isDisplayed)
    }

    /*--------------------------------------------------
     onDismiss
     --------------------------------------------------*/
    func test_onDismiss() throws {
        // setup
        pinCodeScreen.fullscreenWebView = mockWebView
        pinCodeScreen.fullscreenMessage = mockMessage
        pinCodeScreen.isDisplayed = true

        // test
        pinCodeScreen.onDismiss(message: mockMessage)

        // verify
        XCTAssertFalse(pinCodeScreen.isDisplayed)
        XCTAssertNil(pinCodeScreen.fullscreenMessage)
        XCTAssertNil(pinCodeScreen.fullscreenWebView)
    }

    /*--------------------------------------------------
     connectionFailedWithError
     --------------------------------------------------*/

    func test_connectionFailedWithError() throws {
        // test
        pinCodeScreen.connectionFailedWithError(AssuranceConnectionError.clientError)

        // verify
        XCTAssertEqual("showError('Client Disconnected','This client has been disconnected due to an unexpected error. Error Code 4400.', 0);",
                       mockWebView.javaScriptStringReceived)
    }

}
