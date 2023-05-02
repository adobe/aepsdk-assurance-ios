//
// Copyright 2021 Adobe. All rights reserved.
// This file is licensed to you under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License. You may obtain a copy
// of the License at http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software distributed under
// the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR REPRESENTATIONS
// OF ANY KIND, either express or implied. See the License for the specific language
// governing permissions and limitations under the License.
//

@testable import AEPServices
import Foundation
import WebKit
import XCTest

class MockFullscreenMessagePresentable: FullscreenPresentable {
    var showCalled = false
    func show() {
        showCalled = true
    }

    var dismissCalled = false
    func dismiss() {
        dismissCalled = true
    }
}

class MockFloatingButton: FloatingButtonPresentable {
    init() {}

    var setButtonImageCalled = false
    var buttonImageValue: Data?
    func setButtonImage(imageData: Data) {
        setButtonImageCalled = true
        buttonImageValue = imageData
    }
    var setInitialPositionCalled = false
    var initialPositionValue: FloatingButtonPosition?
    func setInitial(position: FloatingButtonPosition) {
        setInitialPositionCalled = true
        initialPositionValue = position
    }

    var showCalled = false
    var showCallCount = 0
    func show() {
        showCalled = true
        showCallCount += 1
    }

    var dismissCalled = false
    func dismiss() {
        dismissCalled = true
    }

}

class MockUIService: UIService {
    public init() {}

    var createFullscreenMessageCalled = false
    var createFullscreenMessageCallCount = 0
    var fullscreenMessage: FullscreenPresentable?
    public func createFullscreenMessage(payload _: String, listener _: FullscreenMessageDelegate?, isLocalImageUsed _: Bool) -> FullscreenPresentable {
        createFullscreenMessageCalled = true
        createFullscreenMessageCallCount += 1
        return fullscreenMessage ?? MockFullscreenMessagePresentable()
    }

    var createFloatingButtonCalled = false
    var floatingButton: FloatingButtonPresentable?
    public func createFloatingButton(listener _: FloatingButtonDelegate) -> FloatingButtonPresentable {
        createFloatingButtonCalled = true
        return floatingButton ?? MockFloatingButton()
    }

}

class MockFullScreenMessage: FullscreenMessage {
    var initializerCalled = false

    init() {
        super.init(payload: "sample payload", listener: nil, isLocalImageUsed: false, messageMonitor: MockMessageMonitor())
    }

    var showCalled = false
    override func show() {
        showCalled = true
    }

    var dismissCalled = false
    override func dismiss() {
        dismissCalled = true
    }

    var hideCalled = false
    override func hide() {
        hideCalled = true
    }

}

class MockMessageMonitor: MessageMonitoring {
    func show(message: AEPServices.Showable, delegateControl: Bool) -> Bool {
        return true
    }
    
    func isMessageDisplayed() -> Bool {
        return false
    }

    func displayMessage() {
    }

    func dismissMessage() {
    }

    func show(message: Showable) -> Bool {
        return true
    }

    func dismiss() -> Bool {
        return true
    }
}

class MockWebView: WKWebView {
    var expectation: XCTestExpectation?
    var expectationCounter = 1
    var javaScriptStringReceived = ""
    var javaScriptMethodInvokeCount = 0
    var throwJavascriptError = false

    override func evaluateJavaScript(_ javaScriptString: String, completionHandler: ((Any?, Error?) -> Void)? = nil) {
        if throwJavascriptError {
            completionHandler?(nil, MockError.error("mockError"))
        }
        javaScriptMethodInvokeCount += 1
        javaScriptStringReceived = javaScriptString
        if javaScriptMethodInvokeCount == expectationCounter {
            expectation?.fulfill()
        }
    }
}

enum MockError: Error {
    case error(String)
}
