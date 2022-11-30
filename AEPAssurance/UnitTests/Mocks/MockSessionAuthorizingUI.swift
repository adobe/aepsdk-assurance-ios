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
@testable import AEPServices
import Foundation

class MockSessionAuthorizingUI: SessionAuthorizingUI {
    
    var displayed: Bool
    
    required init(withPresentationDelegate presentationDelegate: AssurancePresentationDelegate) {
        displayed = false
    }

    var showCalled = false
    func show() {
        showCalled = true
        displayed = true
    }
    
    var onSessionConnectingCalled = false
    func sessionConnecting() {
        onSessionConnectingCalled = true
    }
    
    var onSessionInitializedCalled = false
    func sessionInitialized() {
        onSessionInitializedCalled = true
    }
    
    var onSessionConnectedCalled = false
    func sessionConnected() {
        onSessionConnectedCalled = true
    }
    
    var onSessionDisconnectedCalled = false
    func sessionDisconnected() {
        onSessionDisconnectedCalled = true
    }
    
    var sessionConnectionFailed = false
    var sessionConnectionFailedError: AssuranceConnectionError?
    func sessionConnectionFailed(withError error: AssuranceConnectionError) {
        sessionConnectionFailed = true
        sessionConnectionFailedError = error
    }        

}
