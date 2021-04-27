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
@testable import AEPAssurance

class URL_ParserTests: XCTestCase {

    func test_queryParams_happy() throws {
        // setup
        let url = URL.init(string: "griffon://?adb_validation_sessionid=someId&env=stage")
        
        // test
        XCTAssertEqual(2, url?.params.count)
        XCTAssertEqual("someId", url?.params["adb_validation_sessionid"])
        XCTAssertEqual("stage", url?.params["env"])
    }
    
    func test_queryParams_emptyParameter() throws {
        // setup
        let url = URL.init(string: "griffon://?adb_validation_sessionid=someId&env=")
        
        // test
        XCTAssertEqual(2, url?.params.count)
        XCTAssertEqual("someId", url?.params["adb_validation_sessionid"])
        XCTAssertEqual("", url?.params["env"])
    }
    
    func test_queryParams_invalidParameter() throws {
        // setup
        let url = URL.init(string: "griffon://?adb_validation_sessionid=someId&env")
        
        // test
        XCTAssertEqual(1, url?.params.count)
        XCTAssertEqual("someId", url?.params["adb_validation_sessionid"])
    }
    
    func test_queryParams_integerParameter() throws {
        // setup
        let url = URL.init(string: "griffon://?adb_validation_sessionid=someId&env=67")
        
        // test
        XCTAssertEqual(2, url?.params.count)
        XCTAssertEqual("someId", url?.params["adb_validation_sessionid"])
        XCTAssertEqual("67", url?.params["env"])
    }
    
    func test_queryParams_noParameters() throws {
        // setup
        let url = URL.init(string: "griffon://")
        
        // test
        XCTAssertEqual(0, url?.params.count)
    }

}
