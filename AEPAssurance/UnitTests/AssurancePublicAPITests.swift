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
import XCTest

class AEPAssuranceTests: XCTestCase {

    override func setUpWithError() throws {
        EventHub.shared.start()
        registerMockExtension(MockExtension.self)
    }

    override func tearDownWithError() throws {
        unregisterMockExtension(MockExtension.self)
    }

    func test_extensionVersion() throws {
        XCTAssertEqual(AssuranceConstants.EXTENSION_VERSION, Assurance.extensionVersion)
    }

    func test_startSession() {
        // setup
        let validSessionURL = "griffon://?adb_validation_sessionid=f4c4ce1e-11db-4569-a866-7ae3af7c2304"
        let expectation = XCTestExpectation(description: "Start session with valid assurance deeplink URL should dispatch event")

        // event dispatch verification
        EventHub.shared.getExtensionContainer(MockExtension.self)?.registerListener(type: AssuranceConstants.SDKEventType.ASSURANCE, source: EventSource.requestContent) { event in
            XCTAssertEqual(event.data?[AssuranceConstants.EventDataKey.START_SESSION_URL] as! String, validSessionURL)
            expectation.fulfill()
        }

        // test
        Assurance.startSession(url: URL(string: validSessionURL)!)

        // verify
        wait(for: [expectation], timeout: 1)
    }

    func test_startSession_withoutSessionID() {
        // setup
        let expectation = XCTestExpectation(description: "Start session with invalid assurance deeplink URL should not dispatch an event")
        expectation.isInverted = true

        // event dispatch verification
        EventHub.shared.getExtensionContainer(MockExtension.self)?.registerListener(type: AssuranceConstants.SDKEventType.ASSURANCE, source: EventSource.requestContent) { _ in
            expectation.fulfill()
        }

        // test invalid URL's
        Assurance.startSession(url: URL(string: "griffon://?no_sessionid=nothing")!)

        // verify
        wait(for: [expectation], timeout: 1)
    }

    func test_startSession_nilURL() {
        // setup
        let expectation = XCTestExpectation(description: "Start session with nil assurance deeplink URL should not dispatch an event")
        expectation.isInverted = true

        // event dispatch verification
        EventHub.shared.getExtensionContainer(MockExtension.self)?.registerListener(type: AssuranceConstants.SDKEventType.ASSURANCE, source: EventSource.requestContent) { _ in
            expectation.fulfill()
        }

        // test invalid URL's
        Assurance.startSession(url: nil)

        // verify
        wait(for: [expectation], timeout: 1)
    }

    //********************************************************************
    // Private methods
    //********************************************************************

    private func registerMockExtension<T: Extension> (_ type: T.Type) {
        let semaphore = DispatchSemaphore(value: 0)
        EventHub.shared.registerExtension(type) { _ in
            semaphore.signal()
        }

        semaphore.wait()
    }

    private func unregisterMockExtension<T: Extension> (_ type: T.Type) {
        let semaphore = DispatchSemaphore(value: 0)
        EventHub.shared.unregisterExtension(type) { _ in
            semaphore.signal()
        }

        semaphore.wait()
    }

}
