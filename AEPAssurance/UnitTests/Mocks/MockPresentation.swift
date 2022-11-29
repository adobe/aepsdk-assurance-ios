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

@testable import AEPAssurance
@testable import AEPCore
import Foundation
import XCTest

class MockAuthorizingPresentation : AssuranceAuthorizingPresentation {
    
    var expectation: XCTestExpectation?
    override init(authorizingView: SessionAuthorizingUI) {
        super.init(authorizingView: authorizingView)
    }
    
    var showCalled = false
    override func show() {
        showCalled = true
    }
    
    var sessionConnectingCalled = false
    override func sessionConnecting() {
        sessionConnectingCalled = true
    }
    
    var sessionConnectedCalled = false
    override func sessionConnected() {
        sessionConnectedCalled = true
    }
    
    
    var sessionDisconnectedCalled = false
    override func sessionDisconnected() {
        sessionDisconnectedCalled = true
    }
    
    var sessionConnectionErrorCalled = false
    var sessionConnectionErrorValue : AssuranceConnectionError?
    override func sessionConnectionError(error: AssuranceConnectionError) {
        sessionConnectionErrorCalled = true
        sessionConnectionErrorValue = error
    }
}
