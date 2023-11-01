//
// Copyright 2022 Adobe. All rights reserved.
// This file is licensed to you under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License. You may obtain a copy
// of the License at http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software distributed under
// the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR REPRESENTATIONS
// OF ANY KIND, either express or implied. See the License for the specific language
// governing permissions and limitations under the License.
//


import Foundation
@testable import AEPAssurance
@testable import AEPCore
import XCTest

class MockStateManager : AssuranceStateManager {
    
    var expectation: XCTestExpectation?
    required override init(_ runtime: ExtensionRuntime) {
        super.init(runtime)
    }

    var getAllExtensionStateDataCalled = false
    override func getAllExtensionStateData() -> [AssuranceEvent] {
        expectation?.fulfill()
        getAllExtensionStateDataCalled = true
        return []
    }
    
    var shareAssuranceStateCalled = false
    var shareAssuranceStateSessionID: String?
    var shareAssuranceStateExpectation = XCTestExpectation(description: "Share assurance state expectation")
    override func shareAssuranceState(withSessionID sessionId: String) {
        shareAssuranceStateCalled = true
        shareAssuranceStateSessionID = sessionId
        shareAssuranceStateExpectation.fulfill()
    }
    
    var clearAssuranceStateCalled = false
    override func clearAssuranceState() {
        clearAssuranceStateCalled = true
    }
    
    var orgIDReturnValue: String?
    override func getURLEncodedOrgID() -> String? {
        return orgIDReturnValue
    }
    
    func setConnectedURLString(_ url : String?) {
        self.connectedWebSocketURL = url
    }
    
}
