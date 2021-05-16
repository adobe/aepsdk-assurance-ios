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
import XCTest

class PluginFakeEventTests: XCTestCase {

    let plugin = PluginFakeEvent()

    override func setUpWithError() throws {
        EventHub.shared.start()
        registerMockExtension(MockExtension.self)
    }

    override func tearDownWithError() throws {
        unregisterMockExtension(MockExtension.self)
    }

    func test_vendor() {
        XCTAssertEqual(AssuranceConstants.Vendor.MOBILE, plugin.vendor)
    }

    func test_commandType() {
        XCTAssertEqual(AssuranceConstants.CommandType.FAKE_EVENT, plugin.commandType)
    }

    func test_commandFakeEvent() {
        // setup
        let expectation = XCTestExpectation(description: "Fake event should be dispatched when command is recieved with correct details")

        // event dispatch verification
        EventHub.shared.getExtensionContainer(MockExtension.self)?.registerListener(type: "fakeEventType", source: "fakeEventSource") { _ in
            expectation.fulfill()
        }

        // test
        plugin.receiveEvent(prepareFakeEventCommand())

        // verify
        wait(for: [expectation], timeout: 1)
    }

    func test_commandFakeEvent_withNoDetails() {
        // setup
        let payload: [String: AnyCodable] = ["type": "Control"]
        let expectation = XCTestExpectation(description: "PluginFakeEvent should not dispatch event when there are no details in the command")
        expectation.isInverted = true

        // event dispatch verification
        EventHub.shared.getExtensionContainer(MockExtension.self)?.registerListener(type: "fakeEventType", source: "fakeEventSource") { _ in
            expectation.fulfill()
        }

        // test
        plugin.receiveEvent(AssuranceEvent.init(type: AssuranceConstants.EventType.CONTROL, payload: payload))

        // verify
        wait(for: [expectation], timeout: 0.3)
    }

    func test_commandFakeEvent_withNoEventName() {
        // setup
        let eventInfo: [String: String] =
            ["eventType": "fakeEventType",
             "eventSource": "fakeEventSource"]

        let payload: [String: AnyCodable] = [
            "detail": AnyCodable.init(eventInfo),
            "type": "Control"]
        let expectation = XCTestExpectation(description: "PluginFakeEvent should not dispatch event when eventName is not available")
        expectation.isInverted = true

        // event dispatch verification
        EventHub.shared.getExtensionContainer(MockExtension.self)?.registerListener(type: "fakeEventType", source: "fakeEventSource") { _ in
            expectation.fulfill()
        }

        // test
        plugin.receiveEvent(AssuranceEvent.init(type: AssuranceConstants.EventType.CONTROL, payload: payload))

        // verify
        wait(for: [expectation], timeout: 0.3)
    }

    func test_commandFakeEvent_withNoEventType() {
        // setup
        let eventInfo: [String: String] =
            ["eventName": "Configuration Update",
             "eventSource": "fakeEventSource"]

        let payload: [String: AnyCodable] = [
            "detail": AnyCodable.init(eventInfo),
            "type": "Control"]
        let expectation = XCTestExpectation(description: "PluginFakeEvent should not dispatch event when eventType is not available")
        expectation.isInverted = true

        // event dispatch verification
        EventHub.shared.getExtensionContainer(MockExtension.self)?.registerListener(type: "fakeEventType", source: "fakeEventSource") { _ in
            expectation.fulfill()
        }

        // test
        plugin.receiveEvent(AssuranceEvent.init(type: AssuranceConstants.EventType.CONTROL, payload: payload))

        // verify
        wait(for: [expectation], timeout: 0.3)
    }

    func test_commandFakeEvent_withNoEventSource() {
        // setup
        let eventInfo: [String: String] =
            ["eventName": "Configuration Update",
             "eventType": "fakeEventType"]

        let payload: [String: AnyCodable] = [
            "detail": AnyCodable.init(eventInfo),
            "type": "Control"]
        let expectation = XCTestExpectation(description: "PluginFakeEvent should not dispatch event when eventSource is not available")
        expectation.isInverted = true

        // event dispatch verification
        EventHub.shared.getExtensionContainer(MockExtension.self)?.registerListener(type: "fakeEventType", source: "fakeEventSource") { _ in
            expectation.fulfill()
        }

        // test
        plugin.receiveEvent(AssuranceEvent.init(type: AssuranceConstants.EventType.CONTROL, payload: payload))

        // verify
        wait(for: [expectation], timeout: 0.3)
    }

    // MARK: - Private functions

    private func prepareFakeEventCommand() -> AssuranceEvent {
        let eventInfo: [String: String] =
            ["eventName": "Configuration Update",
             "eventType": "fakeEventType",
             "eventSource": "fakeEventSource"]

        let payload: [String: AnyCodable] = [
            "detail": AnyCodable.init(eventInfo),
            "type": "Control"]
        return AssuranceEvent.init(type: AssuranceConstants.EventType.CONTROL, payload: payload)
    }

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
