/*
 Copyright 2022 Adobe. All rights reserved.
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

class AssuranceStateManagerTests: XCTestCase {
    
    let CONSENT_SHARED_STATE_NAME = "com.adobe.edge.consent"
    let runtime = TestableExtensionRuntime()
    var stateManager: AssuranceStateManager!
    var mockDataStore = MockDataStore()
    
    override func setUp() {
        ServiceProvider.shared.namedKeyValueService = mockDataStore
        stateManager = AssuranceStateManager(runtime)
    }
    
    override func tearDown() {
        runtime.reset()
    }
    
    func test_stateManager_createsAndPersistsClientId() throws {
        // test
        XCTAssertNotNil(stateManager.clientID)
        XCTAssertEqual(1, mockDataStore.dict.count)
        XCTAssertEqual(stateManager.clientID, mockDataStore.dict[AssuranceConstants.DataStoreKeys.CLIENT_ID] as! String)
    }

    func test_assuranceState_loadsPersistedClientID() throws {
        // setup
        mockClientIDToPersistence(clientID: "mockClientID")

        // test
        XCTAssertEqual("mockClientID", stateManager.clientID)
    }


    func test_stateManager_getAllExtensionStateData() throws {
        // setup
        runtime.simulateSharedState(extensionName: AssuranceConstants.SharedStateName.EVENT_HUB, event: nil, data: (sampleEventHubState, .set))
        runtime.simulateSharedState(extensionName: AssuranceConstants.SharedStateName.CONFIGURATION, event: nil, data: (sampleConfigurationState, .set))
        runtime.simulateXDMSharedState(for: CONSENT_SHARED_STATE_NAME, data: (sampleConsentState, .set))

        // test
        let resultEvents = stateManager.getAllExtensionStateData()

        // verify that the required shared state events are generated
        XCTAssertEqual(3, resultEvents.count)
        XCTAssertTrue(resultEvents.hasEventWithName("EventHub State"))
        XCTAssertTrue(resultEvents.hasEventWithName("Configuration State"))
        XCTAssertTrue(resultEvents.hasEventWithName("\(CONSENT_SHARED_STATE_NAME) XDM State"))
    }

    func test_stateManager_getAllExtensionStateData_WhenNoExtensionRegistered() throws {
        // setup
        runtime.simulateSharedState(extensionName: AssuranceConstants.SharedStateName.EVENT_HUB, event: nil, data: ([:], .set))

        // test
        let resultEvents = stateManager.getAllExtensionStateData()

        // verify that the required shared state events are generated
        XCTAssertEqual(0, resultEvents.count)
    }
    
    
    func test_stateManager_getURLEncodedOrgID() throws {
        // setup
        runtime.simulateSharedState(extensionName: AssuranceConstants.SharedStateName.CONFIGURATION, event: nil, data: (sampleConfigurationState, .set))

        // test and verify
        XCTAssertEqual("472B898333E9F7BC7F383101@AdobeOrg", stateManager.getURLEncodedOrgID())
    }
    
    func test_stateManager_getURLEncodedOrgID_whenNoConfig() throws {
        // setup
        runtime.simulateSharedState(extensionName: AssuranceConstants.SharedStateName.CONFIGURATION, event: nil, data: (nil, .set))

        // test and verify
        XCTAssertNil(stateManager.getURLEncodedOrgID())
    }


    func test_stateManager_shareAssuranceState_happy() throws {
        // test
        stateManager.shareAssuranceState(withSessionID: "newSessionID")

        // verify
        XCTAssertEqual(1, runtime.sharedStates.count)
        XCTAssertNotNil(runtime.firstSharedState?[AssuranceConstants.SharedStateKeys.CLIENT_ID])
        XCTAssertNotNil(runtime.firstSharedState?[AssuranceConstants.SharedStateKeys.SESSION_ID])
        XCTAssertNotNil(runtime.firstSharedState?[AssuranceConstants.SharedStateKeys.INTEGRATION_ID])
        XCTAssertEqual(stateManager.clientID, runtime.firstSharedState?[AssuranceConstants.SharedStateKeys.CLIENT_ID] as? String)
        XCTAssertEqual("newSessionID", runtime.firstSharedState?[AssuranceConstants.SharedStateKeys.SESSION_ID] as? String)
        XCTAssertEqual("newSessionID" + "|" + "\(stateManager.clientID)", runtime.firstSharedState?[AssuranceConstants.SharedStateKeys.INTEGRATION_ID] as? String)
    }

    func test_stateManager_clearAssuranceState() throws {
        // setup
        stateManager.shareAssuranceState(withSessionID: "newSessionID") // first set the shared state

        // test
        stateManager.clearAssuranceState() // and then attempt to clear it

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

    private var sampleEventHubState: [String: Any] {
        let data = """
                   {
                     "extensions": {
                       "com.adobe.module.configuration": {
                         "version": "1.8.0",
                         "friendlyName": "Configuration"
                       },
                       "com.adobe.edge.consent": {
                         "version": "1.0.0"
                       }
                     },
                     "version": "1.8.0"
                   }
                   """.data(using: .utf8)!

        return try! (JSONSerialization.jsonObject(with: data, options: []) as? [String: Any])!
    }

    private var sampleConfigurationState: [String: Any] {
        let data = """
                   {
                     "global.privacy" :  "optedin",
                     "target.timout" :  5,
                     "analytics.rsid": "rsids",
                     "experienceCloud.org": "472B898333E9F7BC7F383101@AdobeOrg"
                   }
                   """.data(using: .utf8)!

        return try! (JSONSerialization.jsonObject(with: data, options: []) as? [String: Any])!
    }

    private var sampleConsentState: [String: Any] {
        let data = """
                    {
                      "consents" : {
                        "collect" : {
                          "val" : "n"
                        }
                      }
                    }
                   """.data(using: .utf8)!

        return try! (JSONSerialization.jsonObject(with: data, options: []) as? [String: Any])!
    }
}
