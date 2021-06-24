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

class ErrorViewTests: XCTestCase {

    let mockUIService = MockUIService()
    let mockMessage = MockFullScreenMessage()
    let mockWebView = MockWebView()
    var errorView: ErrorView!

    override func setUp() {
        ServiceProvider.shared.uiService = mockUIService
        mockUIService.fullscreenMessage = mockMessage
        errorView = ErrorView(.clientError)
        errorView.fullscreenWebView = mockWebView
    }

    func test_errorView_display() throws {
        // test
        errorView.display()

        // verify
        XCTAssertTrue(mockUIService.createFullscreenMessageCalled)
        XCTAssertTrue(mockMessage.showCalled)

        // verify the fullscreen message instance stays in memory
        XCTAssertNotNil(errorView.fullscreenMessage)
        XCTAssertNotNil(errorView.fullscreenWebView)
    }

    func test_errorView_loadsCorrectMessage() throws {
        // test
        errorView.webViewDidFinishInitialLoading(webView: mockWebView)

        // verify that the javascript to show error is called
        XCTAssertEqual(String(format: "showError('%@','%@', 0);", AssuranceConnectionError.clientError.info.name, AssuranceConnectionError.clientError.info.description), mockWebView.javaScriptStringReceived)
    }

    func test_errorView_cancelClicked() throws {
        // test
        let shouldHandleURL = errorView.overrideUrlLoad(message: mockMessage, url: "adbinapp://cancel?")

        // verify that the message is dismissed
        XCTAssert(mockMessage.dismissCalled)
        XCTAssertFalse(shouldHandleURL)
    }

    func test_errorView_onDismiss() throws {
        // setup initially display the error
        errorView.display()

        // test
        errorView.onDismiss(message: mockMessage)

        // verify fullscreen message and webView instance are removed from memory
        XCTAssertNil(errorView.fullscreenMessage)
        XCTAssertNil(errorView.fullscreenWebView)
    }

    func test_errorView_onShowFailure() throws {
        // test
        XCTAssertNoThrow(errorView.onShowFailure())
    }
}
