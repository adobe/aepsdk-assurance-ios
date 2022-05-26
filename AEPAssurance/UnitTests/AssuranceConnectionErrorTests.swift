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
import XCTest

class AssuranceConnectionErrorTests: XCTestCase {

    func test_AssuranceConnectionErrorEnum() throws {

        // Generic Error
        XCTAssertNotNil(AssuranceConnectionError.genericError.info.name)
        XCTAssertNotNil(AssuranceConnectionError.genericError.info.description)
        XCTAssertTrue(AssuranceConnectionError.genericError.info.shouldRetry)

        // No PinCode Error
        XCTAssertNotNil(AssuranceConnectionError.noPincode.info.name)
        XCTAssertNotNil(AssuranceConnectionError.noPincode.info.description)
        XCTAssertTrue(AssuranceConnectionError.noPincode.info.shouldRetry)

        // NoURL Error
        XCTAssertNotNil(AssuranceConnectionError.noURL.info.name)
        XCTAssertNotNil(AssuranceConnectionError.noURL.info.description)
        XCTAssertFalse(AssuranceConnectionError.noURL.info.shouldRetry)

        // noOrgId Error
        XCTAssertNotNil(AssuranceConnectionError.noOrgId.info.name)
        XCTAssertNotNil(AssuranceConnectionError.noOrgId.info.description)
        XCTAssertFalse(AssuranceConnectionError.noOrgId.info.shouldRetry)

        // orgIDMismatch Error
        XCTAssertNotNil(AssuranceConnectionError.orgIDMismatch.info.name)
        XCTAssertNotNil(AssuranceConnectionError.orgIDMismatch.info.description)
        XCTAssertFalse(AssuranceConnectionError.orgIDMismatch.info.shouldRetry)

        // connectionLimit Error
        XCTAssertNotNil(AssuranceConnectionError.connectionLimit.info.name)
        XCTAssertNotNil(AssuranceConnectionError.connectionLimit.info.description)
        XCTAssertFalse(AssuranceConnectionError.connectionLimit.info.shouldRetry)

        // eventLimit Error
        XCTAssertNotNil(AssuranceConnectionError.eventLimit.info.name)
        XCTAssertNotNil(AssuranceConnectionError.eventLimit.info.description)
        XCTAssertFalse(AssuranceConnectionError.eventLimit.info.shouldRetry)

        // clientError Error
        XCTAssertNotNil(AssuranceConnectionError.clientError.info.name)
        XCTAssertNotNil(AssuranceConnectionError.clientError.info.description)
        XCTAssertFalse(AssuranceConnectionError.clientError.info.shouldRetry)

        // userCancelled Error
        XCTAssertNotNil(AssuranceConnectionError.userCancelled.info.name)
        XCTAssertNotNil(AssuranceConnectionError.userCancelled.info.description)
        XCTAssertFalse(AssuranceConnectionError.userCancelled.info.shouldRetry)
        
        // deleted session error
        XCTAssertNotNil(AssuranceConnectionError.deletedSession.info.name)
        XCTAssertNotNil(AssuranceConnectionError.deletedSession.info.description)
        XCTAssertFalse(AssuranceConnectionError.deletedSession.info.shouldRetry)

    }
}
