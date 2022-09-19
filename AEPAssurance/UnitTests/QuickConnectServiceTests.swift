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
@testable import AEPServices
import XCTest

final class QuickConnectServiceTests: XCTestCase {
    var mockNetworkService: MockNetworkService!

    override func setUp() {
        mockNetworkService = MockNetworkService()
        ServiceProvider.shared.networkService = mockNetworkService
    }

    func testRegisterDeviceSuccess() {
        let testClientID = "clientID"
        let testOrgID = "orgID"
        let quickConnectService = QuickConnectService()
        quickConnectService.registerDevice(clientID: testClientID, orgID: testOrgID) { result in
            
        }
    }
    


}
