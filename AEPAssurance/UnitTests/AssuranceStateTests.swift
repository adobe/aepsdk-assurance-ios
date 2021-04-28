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
import AEPServices
import Foundation
import XCTest

class AssuranceStateTests: XCTestCase {

    var assurance: Assurance!
    var runtime: TestableExtensionRuntime!

    var mockDataStore: MockDataStore {
        return ServiceProvider.shared.namedKeyValueService as! MockDataStore
    }

    override func setUp() {
        ServiceProvider.shared.namedKeyValueService = MockDataStore()
        runtime = TestableExtensionRuntime()
        assurance = Assurance(runtime: runtime)
        assurance.onRegistered()
    }

    override func tearDown() {
        runtime.reset()
    }

    func test_assuranceState_createsAndPersistsClientId() throws {
        // test
        XCTAssertNotNil(assurance.clientID)
        XCTAssertEqual(1, mockDataStore.dict.count)
        XCTAssertEqual(assurance.clientID, mockDataStore.dict[AssuranceConstants.DataStoreKeys.CLIENT_ID] as! String)
    }

    func test_assuranceState_loadsPersistedClientID() throws {
        // setup
        mockClientIDToPersistence(clientID: "mockClientID")

        // test
        XCTAssertEqual("mockClientID", assurance.clientID)
    }

    func test_assuranceState_loadsPersistedSessionID() throws {
        // setup
        mockSessionIDToPersistence(sessionID: "mockSessionID")

        // test
        XCTAssertEqual("mockSessionID", assurance.sessionId)
    }

    func test_assuranceState_savesSessionIDToPersistence() throws {
        // test
        assurance.sessionId = "newSessionID"

        // verify
        XCTAssertEqual(1, mockDataStore.dict.count)
        XCTAssertEqual("newSessionID", mockDataStore.dict[AssuranceConstants.DataStoreKeys.SESSION_ID] as! String)
        XCTAssertEqual("newSessionID", assurance.sessionId)
    }

    func test_assuranceState_shareSharedState_nilSessionID() throws {
        // test
        assurance.shareSharedState()

        // verify
        XCTAssertEqual(1, runtime.sharedStates.count)
        XCTAssertTrue(runtime.firstSharedState!.isEmpty)
    }

    func test_assuranceState_shareSharedState_happy() throws {
        // test
        assurance.sessionId = "newSessionID"

        // test
        assurance.shareSharedState()

        // verify
        XCTAssertEqual(1, runtime.sharedStates.count)
        XCTAssertNotNil(runtime.firstSharedState?[AssuranceConstants.SharedStateKeys.CLIENT_ID])
        XCTAssertNotNil(runtime.firstSharedState?[AssuranceConstants.SharedStateKeys.SESSION_ID])
        XCTAssertNotNil(runtime.firstSharedState?[AssuranceConstants.SharedStateKeys.INTEGRATION_ID])
        XCTAssertEqual(assurance.clientID, runtime.firstSharedState?[AssuranceConstants.SharedStateKeys.CLIENT_ID] as? String)
        XCTAssertEqual(assurance.sessionId, runtime.firstSharedState?[AssuranceConstants.SharedStateKeys.SESSION_ID] as? String)
        XCTAssertEqual("\(assurance.clientID)" + "|" + "\(assurance.sessionId!)", runtime.firstSharedState?[AssuranceConstants.SharedStateKeys.INTEGRATION_ID] as? String)
    }

    func test_assuranceState_clearSharedState() throws {
        // setup
        assurance.sessionId = "newSessionID"

        // test
        assurance.shareSharedState() // first set the shared state
        assurance.clearSharedState() // and then attempt to clear it

        // verify
        XCTAssertEqual(2, runtime.sharedStates.count)
        XCTAssertFalse(runtime.firstSharedState!.isEmpty)
        XCTAssertTrue(runtime.secondSharedState!.isEmpty)
    }

    //********************************************************************
    // Private methods
    //********************************************************************

    private func mockClientIDToPersistence(clientID: String) {
        mockDataStore.dict[AssuranceConstants.DataStoreKeys.CLIENT_ID] = clientID
    }

    private func mockSessionIDToPersistence(sessionID: String) {
        mockDataStore.dict[AssuranceConstants.DataStoreKeys.SESSION_ID] = sessionID
    }

}
