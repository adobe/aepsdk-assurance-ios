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

import XCTest
import Foundation
import AEPServices
@testable import AEPAssurance

class AssuranceStateTests: XCTestCase {
    
    var state : AssuranceState!
    var mockDataStore: MockDataStore {
        return ServiceProvider.shared.namedKeyValueService as! MockDataStore
    }
    
    override func setUp() {
        ServiceProvider.shared.namedKeyValueService = MockDataStore()
        state = AssuranceState()
    }

    func test_assuranceState_createsAndPersistsClientId() throws {
        // test
        XCTAssertNotNil(state.clientID)
        XCTAssertEqual(1, mockDataStore.dict.count)
        XCTAssertEqual(state.clientID, mockDataStore.dict[AssuranceConstants.DataStoteKeys.CLIENT_ID] as! String)
    }
    
    func test_assuranceState_loadsPersistedClientID() throws {
        // setup
        mockClientIDToPersistence(clientID: "mockClientID")
        
        // test
        XCTAssertEqual("mockClientID", state.clientID)
    }
    
    func test_assuranceState_loadsPersistedSessionID() throws {
        // setup
        mockSessionIDToPersistence(sesssionID: "mockSessionID")
        
        // test
        XCTAssertEqual("mockSessionID", state.sessionId)
    }
    
    func test_assuranceState_savesSessionIDToPersistence() throws {
        // test
        state.sessionId = "newSessionID"
        
        // verify
        XCTAssertEqual(1, mockDataStore.dict.count)
        XCTAssertEqual("newSessionID", mockDataStore.dict[AssuranceConstants.DataStoteKeys.SESSION_ID] as! String)
        XCTAssertEqual("newSessionID", state.sessionId)
    }
    
    func test_assuranceState_getSharedState_nilSessonID() throws {
        // test
        let sharedState = state.getSharedStateData()
        
        // verify
        XCTAssertNil(sharedState)
    }
    
    func test_assuranceState_getSharedState_happy() throws {
        // test
        state.sessionId = "newSessionID"
        
        // test
        let sharedState = state.getSharedStateData()
        
        // verify
        XCTAssertNotNil(sharedState?[AssuranceConstants.SharedStateKeys.CLIENT_ID])
        XCTAssertNotNil(sharedState?[AssuranceConstants.SharedStateKeys.SESSION_ID])
        XCTAssertNotNil(sharedState?[AssuranceConstants.SharedStateKeys.INTEGRATION_ID])
        XCTAssertEqual(state.clientID, sharedState?[AssuranceConstants.SharedStateKeys.CLIENT_ID])
        XCTAssertEqual(state.sessionId, sharedState?[AssuranceConstants.SharedStateKeys.SESSION_ID])
        XCTAssertEqual("\(state.clientID)" + "|" + "\(state.sessionId!)", sharedState?[AssuranceConstants.SharedStateKeys.INTEGRATION_ID])
    }
    
    //********************************************************************
    // Private methods
    //********************************************************************
    
    private func mockClientIDToPersistence(clientID : String) {
        mockDataStore.dict[AssuranceConstants.DataStoteKeys.CLIENT_ID] = clientID;
    }
    
    private func mockSessionIDToPersistence(sesssionID : String) {
        mockDataStore.dict[AssuranceConstants.DataStoteKeys.SESSION_ID] = sesssionID;
    }
    
}
