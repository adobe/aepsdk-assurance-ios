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
import Foundation
import XCTest

class AssuranceEnvironmentTests: XCTestCase {

    func test_assuranceEnvironment_enumCreation() throws {
        let devEnum = AssuranceEnvironment.init(envString: "dev")
        let qaEnum = AssuranceEnvironment.init(envString: "qa")
        let stageEnum = AssuranceEnvironment.init(envString: "stage")
        let prodEnum = AssuranceEnvironment.init(envString: "")
        let defaultEnum = AssuranceEnvironment.init(envString: "wonder what i am")

        XCTAssertEqual(devEnum, AssuranceEnvironment.dev)
        XCTAssertEqual(qaEnum, AssuranceEnvironment.qa)
        XCTAssertEqual(stageEnum, AssuranceEnvironment.stage)
        XCTAssertEqual(prodEnum, AssuranceEnvironment.prod)
        XCTAssertEqual(defaultEnum, AssuranceEnvironment.prod)
    }

    func test_assuranceEnvironment_URLFormat() throws {
        XCTAssertEqual("-dev", AssuranceEnvironment.dev.urlFormat)
        XCTAssertEqual("-qa", AssuranceEnvironment.qa.urlFormat)
        XCTAssertEqual("-stage", AssuranceEnvironment.stage.urlFormat)
        XCTAssertEqual("", AssuranceEnvironment.prod.urlFormat)
    }

}
