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

class AssuranceSessionDetailsTests: XCTestCase {
    
    func test_initWithURLString() throws {
        // test
        let sessionDetails = try AssuranceSessionDetails(withURLString: "wss://connect.griffon.adobe.com/client/v1?sessionId=4af99a7f-f900-4558-8394-09f665e1b8ae&token=8706&orgId=972C898555E9F7BC7F000101@AdobeOrg&clientId=05222CA5-2763-436C-8F69-DB4CA89F6E8B")
        
        // validate
        XCTAssertEqual("4af99a7f-f900-4558-8394-09f665e1b8ae", sessionDetails.sessionId)
        XCTAssertEqual("05222CA5-2763-436C-8F69-DB4CA89F6E8B", sessionDetails.clientID)
        XCTAssertEqual("972C898555E9F7BC7F000101@AdobeOrg", sessionDetails.orgId)
        XCTAssertEqual("8706", sessionDetails.token)
        XCTAssertEqual(.prod, sessionDetails.environment)
    }
    
    func test_initWithURLString_invalidURL() throws {
        // setup
        var capturedError: AssuranceSessionDetailBuilderError?
        
        // test
        XCTAssertThrowsError(try AssuranceSessionDetails(withURLString: "")) { error in
            capturedError = error as? AssuranceSessionDetailBuilderError
        }
        
        // verify
        XCTAssertEqual("Not a vaild URL", capturedError?.message)
    }
    
    func test_initWithURLString_noSessionId() throws {
        // setup
        var capturedError: AssuranceSessionDetailBuilderError?
        
        // test
        XCTAssertThrowsError(try AssuranceSessionDetails(withURLString: "wss://connect-dev.griffon.adobe.com/client/v1?token=8706&orgId=sampleOrg&clientId=sampleCId")) { error in
            capturedError = error as? AssuranceSessionDetailBuilderError
        }
        
        // verify
        XCTAssertEqual("No SessionId", capturedError?.message)
    }
    
    func test_initWithURLString_noClientId() throws {
        // setup
        var capturedError: AssuranceSessionDetailBuilderError?
        
        // test
        XCTAssertThrowsError(try AssuranceSessionDetails(withURLString: "wss://connect-dev.griffon.adobe.com/client/v1?sessionId=sampleSId&token=8706&orgId=sampleOrg")) { error in
            capturedError = error as? AssuranceSessionDetailBuilderError
        }
        
        // verify
        XCTAssertEqual("No ClientId", capturedError?.message)
    }
    
    func test_initWithURLString_noOrgId() throws {
        // setup
        var capturedError: AssuranceSessionDetailBuilderError?
        
        // test
        XCTAssertThrowsError(try AssuranceSessionDetails(withURLString: "wss://connect-dev.griffon.adobe.com/client/v1?sessionId=sampleSId&token=8706&clientId=sampleCId")) { error in
            capturedError = error as? AssuranceSessionDetailBuilderError
        }
        
        // verify
        XCTAssertEqual("No OrgId", capturedError?.message)
    }

    func test_initWithURLString_noPinCode() throws {
        // setup
        var capturedError: AssuranceSessionDetailBuilderError?

        // test
        XCTAssertThrowsError(try AssuranceSessionDetails(withURLString: "wss://connect-dev.griffon.adobe.com/client/v1?sessionId=sampleSId&orgId=sampleOrg&clientId=sampleCId")) { error in
            capturedError = error as? AssuranceSessionDetailBuilderError
        }

        // verify
        XCTAssertEqual("No Token", capturedError?.message)
    }
    
    func test_initWithURLString_noHost() throws {
        // setup
        var capturedError: AssuranceSessionDetailBuilderError?

        // test
        XCTAssertThrowsError(try AssuranceSessionDetails(withURLString: "connect-dev.griffon.adobe.com/client/v1?sessionId=sampleSId&token=8706&orgId=sampleOrg&clientId=sampleCId")) { error in
            capturedError = error as? AssuranceSessionDetailBuilderError
        }

        // verify
        XCTAssertEqual("URL has no host", capturedError?.message)
    }
    
    func test_initWithURLString_DevEnvironment() throws {
        // test
        let sessionDetails = try AssuranceSessionDetails(withURLString: "wss://connect-dev.griffon.adobe.com/client/v1?sessionId=sampleSId&token=8706&orgId=sampleOrg&clientId=sampleCId")
        
        // validate
        XCTAssertEqual(.dev, sessionDetails.environment)
    }
    
    func test_initWithURLString_StageEnvironment() throws {
        // test
        let sessionDetails = try AssuranceSessionDetails(withURLString: "wss://connect-stage.griffon.adobe.com/client/v1?sessionId=sampleSId&token=8706&orgId=sampleOrg&clientId=sampleCId")
        
        // validate
        XCTAssertEqual(.stage, sessionDetails.environment)
    }
    
    func test_initWithURLString_InvalidEnvironment() throws {
        // test
        let sessionDetails = try AssuranceSessionDetails(withURLString: "wss://connect-invalid.griffon.adobe.com/client/v1?sessionId=sampleSId&token=8706&orgId=sampleOrg&clientId=sampleCId")
        
        // validate
        XCTAssertEqual(.prod, sessionDetails.environment)
    }
    
    func test_initWithSessionId() {
        // test
        let sessionDetails = AssuranceSessionDetails(sessionId: "sampleSessionId", clientId: "sampleClientId", environment: .dev)
        
        // validate
        XCTAssertEqual("sampleSessionId", sessionDetails.sessionId)
        XCTAssertEqual("sampleClientId", sessionDetails.clientID)
        XCTAssertEqual(.dev, sessionDetails.environment)
        XCTAssertNil(sessionDetails.token)
        XCTAssertNil(sessionDetails.orgId)
    }
    
    func test_authenticate() {
        // setup
        let sessionDetails = AssuranceSessionDetails(sessionId: "sampleSessionId", clientId: "sampleClientId", environment: .dev)
        
        // test
        sessionDetails.authenticate(withPIN: "2222", andOrgID: "sampleOrgId")
        let result = sessionDetails.getAuthenticatedSocketURL()
    
        XCTAssertEqual(.success(URL(string: "wss://connect-dev.griffon.adobe.com/client/v1?sessionId=sampleSessionId&token=2222&orgId=sampleOrgId&clientId=sampleClientId")!), result)
    }
    
    func test_getAuthenticatedSocketURL_happy() throws {
        // setup
        let socketURL = "wss://connect-dev.griffon.adobe.com/client/v1?sessionId=sampleSId&token=8706&orgId=sampleOrg&clientId=sampleCId"
        let sessionDetails = try AssuranceSessionDetails(withURLString: socketURL)
            
        // test
        let result = sessionDetails.getAuthenticatedSocketURL()
        
        // validate
        XCTAssertEqual(.success(URL(string: socketURL)!), result)
    }
    
    func test_getAuthenticatedSocketURL_whenNoPin() {
        // setup
        let sessionDetails = AssuranceSessionDetails(sessionId: "sampleSessionId", clientId: "sampleClientId", environment: .dev)
        
        // test
        let result = sessionDetails.getAuthenticatedSocketURL()
        
        XCTAssertEqual(.failure(.noPinCode), result)
    }
    
    func test_getAuthenticatedSocketURL_whenNoOrgId() {
        // setup
        let sessionDetails = AssuranceSessionDetails(sessionId: "sampleSessionId", clientId: "sampleClientId", environment: .dev)
        
        // test
        sessionDetails.token = "2222"
        let result = sessionDetails.getAuthenticatedSocketURL()
        
        XCTAssertEqual(.failure(.noOrgId), result)
    }
    
}
