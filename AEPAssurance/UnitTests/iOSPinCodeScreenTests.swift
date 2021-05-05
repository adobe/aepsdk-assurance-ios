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

    var assurance: Assurance!
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
        assurance = Assurance(runtime: runtime)
        assurance.onRegistered()
        pinCodeScreen = iOSPinCodeScreen.init(withExtension: assurance)
        pinCodeScreen.fullscreenWebView = mockWebView
    }

    override func tearDown() {
        runtime.reset()
    }

    /*--------------------------------------------------
     getSocketURL
     --------------------------------------------------*/
    func test_iOSPinCodeScreen_getSocketURL() throws {
        // setup
        pinCodeScreen.getSocketURL(callback: { _ in })

        // verify that the fullscreen message is displayed
        XCTAssertTrue(mockUIService.createFullscreenMessageCalled)
        XCTAssertTrue(mockMessage.showCalled)
    }

    /*--------------------------------------------------
     Simulate connect clicked
     --------------------------------------------------*/
    func test_iOSPinCodeScreen_connectClicked() throws {
        // setup
        assurance.sessionId =  "mockSessionID"
        let config = [AssuranceConstants.EventDataKey.CONFIG_ORG_ID: "mockorg@adobe.com"]
        runtime.simulateSharedState(extensionName: AssuranceConstants.SharedStateName.CONFIGURATION, event: nil, data: (config as [String: Any], .set))

        // verify that the correct socket url is created
        let expectation = XCTestExpectation(description: "Correct webSocket url should be created")
        expectation.assertForOverFulfill = true
        pinCodeScreen.getSocketURL(callback: { socketURL in
            XCTAssertTrue(socketURL.contains("wss://connect.griffon.adobe.com/client/v1?sessionId=mockSessionID&token=4444&orgId=mockorg@adobe.com&clientId="))
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
        assurance.sessionId =  "mockSessionID"

        // test
        _ = pinCodeScreen.overrideUrlLoad(message: mockMessage, url: "adbinapp://confirm?code=4444")

        // verify that the javascript to show error is called
        XCTAssertEqual(String(format: "showError('%@','%@', 1);", AssuranceSocketError.NO_ORGID.info.name, AssuranceSocketError.NO_ORGID.info.description), mockWebView.javaScriptStringReceived)
    }

    /*--------------------------------------------------
     Simulate connect clicked - when no invalidPinCode
     --------------------------------------------------*/
    func test_iOSPinCodeScreen_connectClicked_invalidPinCode() throws {
        // setup
        assurance.sessionId =  "mockSessionID"

        // test
        _ = pinCodeScreen.overrideUrlLoad(message: mockMessage, url: "adbinapp://confirm?nodata")

        // verify that the javascript to show error is called
        XCTAssertEqual(String(format: "showError('%@','%@', 1);", AssuranceSocketError.NO_PINCODE.info.name, AssuranceSocketError.NO_PINCODE.info.description), mockWebView.javaScriptStringReceived)
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

}
