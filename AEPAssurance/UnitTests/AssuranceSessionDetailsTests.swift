/*
 Copyright 2022 Adobe. All rights reserved.
 This file is licensed to you under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License. You may obtain a copy
 of the License at http:www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing, software distributed under
 the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR REPRESENTATIONS
 OF ANY KIND, either express or implied. See the License for the specific language
 governing permissions and limitations under the License.
 */

@testable import AEPAssurance
import Foundation
import XCTest
import AEPServices

class AssuranceSocketURLTests: XCTestCase {
    
    override func setUp() {
    }
    
    func test_initWithURLString() throws {
        // test
        let sessionDetails = try AssuranceSessionDetails(withURLString: "wss://connect.griffon.adobe.com/client/v1?sessionId=4af99a7f-f900-4558-8394-09f665e1b8ae&token=8706&orgId=972C898555E9F7BC7F000101@AdobeOrg&clientId=05222CA5-2763-436C-8F69-DB4CA89F6E8B")
        
        // validate
        XCTAssertEqual("4af99a7f-f900-4558-8394-09f665e1b8ae", sessionDetails.sessionId)
        XCTAssertEqual("05222CA5-2763-436C-8F69-DB4CA89F6E8B", sessionDetails.clientID)
        XCTAssertEqual("972C898555E9F7BC7F000101@AdobeOrg", sessionDetails.orgId)
        XCTAssertEqual("8706", sessionDetails.pinCode)
        XCTAssertEqual(.prod, sessionDetails.environment)
    }
}
