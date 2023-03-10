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

class PluginConfigModifyTest: XCTestCase {

    var plugin: PluginConfigModify!

    var mockDataStore: MockDataStore {
        return ServiceProvider.shared.namedKeyValueService as! MockDataStore
    }

    override func setUpWithError() throws {
        ServiceProvider.shared.namedKeyValueService = MockDataStore()
        EventHub.shared.start()
        registerMockExtension(MockExtension.self)
        plugin = PluginConfigModify()
    }

    override func tearDownWithError() throws {
        unregisterMockExtension(MockExtension.self)
    }

    func test_vendor() {
        XCTAssertEqual(AssuranceConstants.Vendor.MOBILE, plugin.vendor)
    }

    func test_commandType() {
        XCTAssertEqual(AssuranceConstants.CommandType.CONFIG_UPDATE, plugin.commandType)
    }

    func test_commandConfigModify() {
        // setup
        let expectation = XCTestExpectation(description: "PluginConfigModify should dispatch a configuration update event with the provided config.")

        // verification for event dispatch
        EventHub.shared.getExtensionContainer(MockExtension.self)?.registerListener(type: EventType.configuration, source: EventSource.requestContent) { event in
            let flattenedEventData = event.data?.flattening()
            XCTAssertEqual("value1", flattenedEventData?["config.update.configString"] as? String)
            XCTAssertEqual( 2, flattenedEventData?["config.update.configInt"] as? Int)
            XCTAssertEqual( false, flattenedEventData?["config.update.configBool"] as? Bool)
            expectation.fulfill()
        }

        // test
        let payload  = ["detail": AnyCodable.init(sampleConfigDetails)]
        plugin.receiveEvent(AssuranceEvent.init(type: AssuranceConstants.EventType.CONTROL, payload: payload))

        // assert on expectation
        wait(for: [expectation], timeout: 0.2)

        // verify that the configuration keys are persisted
        let configKeys = mockDataStore.dict[AssuranceConstants.DataStoreKeys.CONFIG_MODIFIED_KEYS] as? [String]
        XCTAssertEqual(3, configKeys?.count)
    }

    func test_onSessionTerminated() {
        // setup
        let expectationBeforeSessionTerminated = XCTestExpectation(description: "PluginConfigModify should dispatch a configuration update event to reset the modified config.")
        EventHub.shared.getExtensionContainer(MockExtension.self)?.registerListener(type: EventType.configuration, source: EventSource.requestContent) { event in
            let flattenedEventData = event.data?.flattening()
            XCTAssertNotNil(flattenedEventData?["config.update.configString"])
            XCTAssertNotNil(flattenedEventData?["config.update.configInt"])
            XCTAssertNotNil(flattenedEventData?["config.update.configBool"])
            expectationBeforeSessionTerminated.fulfill()
        }
        let payload  = ["detail": AnyCodable.init(sampleConfigDetails)]
        plugin.receiveEvent(AssuranceEvent.init(type: AssuranceConstants.EventType.CONTROL, payload: payload))
        let configKeys = mockDataStore.dict[AssuranceConstants.DataStoreKeys.CONFIG_MODIFIED_KEYS] as? [String]
        XCTAssertEqual(3, configKeys?.count)

        wait(for: [expectationBeforeSessionTerminated], timeout: 0.2)
        //
        let expectationAfterSessionTerminated = XCTestExpectation(description: "PluginConfigModify should dispatch a configuration update event to reset the modified config.")

        // verification for event dispatch
        EventHub.shared.getExtensionContainer(MockExtension.self)?.registerListener(type: EventType.configuration, source: EventSource.requestContent) { event in
            let flattenedEventData = event.data?.flattening()
            XCTAssertEqual(NSNull(), flattenedEventData?["config.update.configString"] as! NSNull)
            XCTAssertEqual(NSNull(), flattenedEventData?["config.update.configInt"] as! NSNull)
            XCTAssertEqual(NSNull(), flattenedEventData?["config.update.configBool"] as! NSNull)
            expectationAfterSessionTerminated.fulfill()
        }

        // test
        plugin.onSessionTerminated()

        // verify that the modified config keys in the persistence are removed
        XCTAssertEqual(0, mockDataStore.dict.count)

        // assert on expectation
        wait(for: [expectationAfterSessionTerminated], timeout: 0.2)

    }

    // MARK: - Private methods and variables

    private var sampleConfigDetails: [String: Any] = {
        return ["configString": "value1", "configInt": 2, "configBool": false]
    }()

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
