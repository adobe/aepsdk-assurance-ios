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
@testable import AEPServices
import Foundation
import XCTest

class AssuranceBlobTests: XCTestCase {

    let runtime = TestableExtensionRuntime()
    var stateManager: MockStateManager!
    var mockNetworkService: MockNetworkService!
    var sessionOrchestrator: MockSessionOrchestrator!
    var mockSession: MockSession!
    let sampleData = "sampleData".data(using: .utf8)
    let sampleResponse = """
                {
                    "id" : "mockBlobId"
                }
                """.data(using: .utf8)!

    let errorResponse = """
                {
                    "error" : "BadError"
                }
                """.data(using: .utf8)!

    let invalidJSON = """
                invalidJSONRespponse
                """.data(using: .utf8)!

    override func setUpWithError() throws {
        stateManager = MockStateManager(runtime)
        sessionOrchestrator = MockSessionOrchestrator(stateManager: stateManager)        
        let sessionDetails = AssuranceSessionDetails(sessionId: "mockSessionId", clientId: "mockClientId", environment: .dev)
        mockSession = MockSession(sessionDetails: sessionDetails, stateManager: stateManager, sessionOrchestrator: sessionOrchestrator, outboundEvents: nil)
        mockNetworkService = MockNetworkService()
        ServiceProvider.shared.networkService = mockNetworkService
    }

    func test_sendBlob_makesNetworkRequest() throws {
        // test
        AssuranceBlob.sendBlob(sampleData!, forSession: mockSession, contentType: "png", callback: {_ in })

        // verify
        XCTAssertTrue(mockNetworkService.connectAsyncCalled)
        XCTAssertEqual("https://blob-dev.griffon.adobe.com/api/FileUpload?validationSessionId=mockSessionId", mockNetworkService.networkRequest?.url.absoluteString)
        XCTAssertEqual(sampleData, mockNetworkService.networkRequest?.connectPayload)
        XCTAssertEqual(HttpMethod.post, mockNetworkService.networkRequest?.httpMethod)
        XCTAssertEqual("application/octet-stream", mockNetworkService.networkRequest?.httpHeaders["Content-Type"])
        XCTAssertEqual("png", mockNetworkService.networkRequest?.httpHeaders["File-Content-Type"])
        XCTAssertEqual(30, mockNetworkService.networkRequest?.connectTimeout)
    }

    func test_sendBlob_WhenUploadSuccess() throws {
        // setup
        let expectation = XCTestExpectation(description: "Send Blob should call the callback with valid blobId")
        let mockConnection = HttpConnection.init(data: sampleResponse, response: HTTPURLResponse.init(), error: nil)

        // test
        AssuranceBlob.sendBlob(sampleData!, forSession: mockSession, contentType: "png", callback: {blobId in
            XCTAssertEqual("mockBlobId", blobId)
            expectation.fulfill()
        })

        // verify
        mockNetworkService.completionHandler!(mockConnection)
    }

    func test_sendBlob_WhenUploadError() throws {
        // setup
        let expectation = XCTestExpectation(description: "On Error SendBlob should call the callback with nil")
        let mockConnection = HttpConnection.init(data: errorResponse, response: HTTPURLResponse.init(), error: nil)

        // test
        AssuranceBlob.sendBlob(sampleData!, forSession: mockSession, contentType: "png", callback: {blobId in
            XCTAssertNil(blobId)
            expectation.fulfill()
        })

        // verify
        mockNetworkService.completionHandler!(mockConnection)
    }

    func test_sendBlob_WhenInvalidResponse() throws {
        // setup
        let expectation = XCTestExpectation(description: "On Error SendBlob should call the callback with nil")
        let mockConnection = HttpConnection.init(data: invalidJSON, response: HTTPURLResponse.init(), error: nil)

        // test
        AssuranceBlob.sendBlob(sampleData!, forSession: mockSession, contentType: "png", callback: {blobId in
            XCTAssertNil(blobId)
            expectation.fulfill()
        })

        // verify
        mockNetworkService.completionHandler!(mockConnection)
    }

    func test_sendBlob_WhenNot200ResponseCode() throws {
        // setup
        let expectation = XCTestExpectation(description: "On Error SendBlob should call the callback with nil")
        let errorResponse = HTTPURLResponse(url: URL(string: "https://fakeURL.com")!, statusCode: 404, httpVersion: nil, headerFields: [:])
        let mockConnection = HttpConnection.init(data: invalidJSON, response: errorResponse, error: nil)

        // test
        AssuranceBlob.sendBlob(sampleData!, forSession: mockSession, contentType: "png", callback: {blobId in
            XCTAssertNil(blobId)
            expectation.fulfill()
        })

        // verify
        mockNetworkService.completionHandler!(mockConnection)
    }
}
