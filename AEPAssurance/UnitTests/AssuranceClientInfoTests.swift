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
import XCTest

class AssuranceClientInfoTests: XCTestCase {

    func test_getClientInfo() throws {
        let clientInfo = AssuranceClientInfo.getData()

        // verify client event type
        XCTAssertEqual( "connect", clientInfo[AssuranceConstants.ClientInfoKeys.TYPE]?.stringValue)

        // verify extension version
        XCTAssertEqual(AssuranceConstants.EXTENSION_VERSION, clientInfo[AssuranceConstants.ClientInfoKeys.VERSION]?.stringValue)

        // verify presence of app settings data
        XCTAssertNotNil(clientInfo[AssuranceConstants.ClientInfoKeys.APP_SETTINGS])

        // verify device info
        let deviceInfo = try XCTUnwrap(clientInfo[AssuranceConstants.ClientInfoKeys.DEVICE_INFO]?.dictionaryValue)
        XCTAssertEqual(10, deviceInfo.count)
        XCTAssertEqual("iOS", deviceInfo["Canonical platform name"] as? String)
        XCTAssertNotNil(deviceInfo["Battery level"] as? Int)
        XCTAssertNotNil(deviceInfo["Device name"] as? String)
        XCTAssertNotNil(deviceInfo["Operating system"] as? String)
        XCTAssertNotNil(deviceInfo["Device type"] as? String)
        XCTAssertNotNil(deviceInfo["Screen size"] as? String)
        XCTAssertNotNil(deviceInfo["Location authorization status"] as? String)
        XCTAssertNotNil(deviceInfo["Low power mode enabled"] as? Bool)
        XCTAssertNotNil(deviceInfo["Location service enabled"] as? Bool)
    }

}
