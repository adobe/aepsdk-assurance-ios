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
        let expectedUrl = URL(string: AssuranceConstants.QUICK_CONNECT_BASE_URL + "/create")!
        let testClientId: AnyCodable = "testClientId"
        let testOrgId: AnyCodable = "testOrgId"
        let quickConnectService = QuickConnectService()
        let dataDict: [String: AnyCodable] = ["clientId": testClientId, "orgId": testOrgId, "deviceName": "testDeviceName"]
        let jsonData = try? JSONEncoder().encode(dataDict)
        let validResponse = HTTPURLResponse(url: URL(string: "https://adobe.com")!, statusCode: 200, httpVersion: nil, headerFields: nil)
        let expectedResponse = HttpConnection(data: jsonData, response: validResponse, error: nil)
        mockNetworkService.expectedResponse = expectedResponse
        let expectation = XCTestExpectation(description: "RegisterDevice API invokes completion handler with registeredDevice details")

        quickConnectService.registerDevice(clientID: testClientId.stringValue!, orgID: testOrgId.stringValue!) { error in
            XCTAssertNil(error)
            XCTAssertTrue(self.mockNetworkService.connectAsyncCalled)
            XCTAssertEqual(self.mockNetworkService.networkRequest?.url, expectedUrl)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1.0)
    }

    func testRegisterDeviceFailureInvalidResponseCode() {
        let expectedUrl = URL(string: AssuranceConstants.QUICK_CONNECT_BASE_URL + "/create")!
        let testClientId: AnyCodable = "testClientId"
        let testOrgId: AnyCodable = "testOrgId"
        let quickConnectService = QuickConnectService()
        let dataDict: [String: AnyCodable] = ["clientId": testClientId, "orgId": testOrgId, "deviceName": "testDeviceName"]
        let jsonData = try? JSONEncoder().encode(dataDict)
        let invalidResponse = HTTPURLResponse(url: URL(string: "https://adobe.com")!, statusCode: 404, httpVersion: nil, headerFields: nil)
        let expectedResponse = HttpConnection(data: jsonData, response: invalidResponse, error: nil)
        mockNetworkService.expectedResponse = expectedResponse
        let expectation = XCTestExpectation(description: "RegisterDevice API invokes completion handler with failedToRegisterDevice error")

        quickConnectService.registerDevice(clientID: testClientId.stringValue!, orgID: testOrgId.stringValue!) { error in
            XCTAssertEqual(error, .failedToRegisterDevice(statusCode: 404, responseMessage: "not found"))
            XCTAssertTrue(self.mockNetworkService.connectAsyncCalled)
            XCTAssertEqual(self.mockNetworkService.networkRequest?.url, expectedUrl)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1.0)
    }

    func testRegisterDeviceFailureInvalidResponseData() {
        let expectedUrl = URL(string: AssuranceConstants.QUICK_CONNECT_BASE_URL + "/create")!
        let testClientId: AnyCodable = "testClientId"
        let testOrgId: AnyCodable = "testOrgId"
        let quickConnectService = QuickConnectService()
        let validResponse = HTTPURLResponse(url: URL(string: "https://adobe.com")!, statusCode: 200, httpVersion: nil, headerFields: nil)
        let expectedResponse = HttpConnection(data: nil, response: validResponse, error: nil)
        mockNetworkService.expectedResponse = expectedResponse
        let expectation = XCTestExpectation(description: "RegisterDevice API invokes completion handler with invalid response data error")

        quickConnectService.registerDevice(clientID: testClientId.stringValue!, orgID: testOrgId.stringValue!) { error in
            XCTAssertEqual(error, .invalidResponseData)
            XCTAssertTrue(self.mockNetworkService.connectAsyncCalled)
            XCTAssertEqual(self.mockNetworkService.networkRequest?.url, expectedUrl)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1.0)
    }

    func testGetDeviceStatusSuccess() {
        let expectedUrl = URL(string: AssuranceConstants.QUICK_CONNECT_BASE_URL + "/status")!
        let testClientId: AnyCodable = "testClientId"
        let testOrgId: AnyCodable = "testOrgId"
        let testSessionId: AnyCodable = "testSessionId"
        let testToken: AnyCodable = 123
        let quickConnectService = QuickConnectService()
        let dataDict: [String: AnyCodable] = ["sessionUuid": testSessionId, "token": testToken]
        let jsonData = try? JSONEncoder().encode(dataDict)
        let validResponse = HTTPURLResponse(url: URL(string: "https://adobe.com")!, statusCode: 200, httpVersion: nil, headerFields: nil)
        let expectedResponse = HttpConnection(data: jsonData, response: validResponse, error: nil)
        mockNetworkService.expectedResponse = expectedResponse
        let expectation = XCTestExpectation(description: "GetDeviceStatus API invokes completion handler with device status")

        quickConnectService.getDeviceStatus(clientID: testClientId.stringValue!, orgID: testOrgId.stringValue!) { result in
            switch result {
            case .success((let sessionId, let token)):
                XCTAssertEqual(sessionId, testSessionId.stringValue)
                XCTAssertEqual(token, testToken.intValue)
                XCTAssertTrue(self.mockNetworkService.connectAsyncCalled)
                XCTAssertEqual(self.mockNetworkService.networkRequest?.url, expectedUrl)
                expectation.fulfill()
            case .failure(_):
                XCTFail()
            }
        }

        wait(for: [expectation], timeout: 1.0)
    }

    func testGetDeviceStatusFailureInvalidResponseCode() {
        let expectedUrl = URL(string: AssuranceConstants.QUICK_CONNECT_BASE_URL + "/status")!
        let testClientId: AnyCodable = "testClientId"
        let testOrgId: AnyCodable = "testOrgId"
        let testSessionId: AnyCodable = "testSessionId"
        let testToken: AnyCodable = 123
        let quickConnectService = QuickConnectService()
        let dataDict: [String: AnyCodable] = ["sessionUuid": testSessionId, "token": testToken]
        let jsonData = try? JSONEncoder().encode(dataDict)
        let invalidResponse = HTTPURLResponse(url: URL(string: "https://adobe.com")!, statusCode: 404, httpVersion: nil, headerFields: nil)
        let expectedResponse = HttpConnection(data: jsonData, response: invalidResponse, error: nil)
        mockNetworkService.expectedResponse = expectedResponse
        let expectation = XCTestExpectation(description: "GetDeviceStatus API invokes completion handler with failedToGetDeviceStatus error")

        quickConnectService.getDeviceStatus(clientID: testClientId.stringValue!, orgID: testOrgId.stringValue!) { result in
            switch result {
            case .success(_):
                XCTFail()
            case .failure(let error):
                XCTAssertEqual(error, .failedToGetDeviceStatus(statusCode: 404, responseMessage: "not found"))
                XCTAssertTrue(self.mockNetworkService.connectAsyncCalled)
                XCTAssertEqual(self.mockNetworkService.networkRequest?.url, expectedUrl)
                expectation.fulfill()
            }
        }

        wait(for: [expectation], timeout: 1.0)
    }

    func testGetDeviceStatusFailureInvalidResponseData() {
        let expectedUrl = URL(string: AssuranceConstants.QUICK_CONNECT_BASE_URL + "/status")!
        let testClientId: AnyCodable = "testClientId"
        let testOrgId: AnyCodable = "testOrgId"
        let quickConnectService = QuickConnectService()
        let validResponse = HTTPURLResponse(url: URL(string: "https://adobe.com")!, statusCode: 200, httpVersion: nil, headerFields: nil)
        let expectedResponse = HttpConnection(data: nil, response: validResponse, error: nil)
        mockNetworkService.expectedResponse = expectedResponse
        let expectation = XCTestExpectation(description: "GetDeviceStatus API invokes completion handler with invalidResponseData error")

        quickConnectService.getDeviceStatus(clientID: testClientId.stringValue!, orgID: testOrgId.stringValue!) { result in
            switch result {
            case .success(_):
                XCTFail()
            case .failure(let error):
                XCTAssertEqual(error, .invalidResponseData)
                XCTAssertTrue(self.mockNetworkService.connectAsyncCalled)
                XCTAssertEqual(self.mockNetworkService.networkRequest?.url, expectedUrl)
                expectation.fulfill()
            }
        }

        wait(for: [expectation], timeout: 1.0)

    }

    func testDeleteDeviceSuccess() {
        let expectedUrl = URL(string: AssuranceConstants.QUICK_CONNECT_BASE_URL + "/delete")!
        let testClientId: AnyCodable = "testClientId"
        let testOrgId: AnyCodable = "testOrgId"
        let quickConnectService = QuickConnectService()
        let dataDict: [String: AnyCodable] = ["clientId": testClientId, "orgId": testOrgId, "deviceName": "testDeviceName"]
        let jsonData = try? JSONEncoder().encode(dataDict)
        let validResponse = HTTPURLResponse(url: URL(string: "https://adobe.com")!, statusCode: 200, httpVersion: nil, headerFields: nil)
        let expectedResponse = HttpConnection(data: jsonData, response: validResponse, error: nil)
        mockNetworkService.expectedResponse = expectedResponse
        let expectation = XCTestExpectation(description: "RegisterDevice API invokes completion handler with registeredDevice details")

        quickConnectService.deleteDevice(clientID: testClientId.stringValue!, orgID: testOrgId.stringValue!) { error in
            XCTAssertNil(error)
            XCTAssertTrue(self.mockNetworkService.connectAsyncCalled)
            XCTAssertEqual(self.mockNetworkService.networkRequest?.url, expectedUrl)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1.0)

    }

    func testDeleteDeviceFailureInvalidResponseCode() {
        let expectedUrl = URL(string: AssuranceConstants.QUICK_CONNECT_BASE_URL + "/delete")!
        let testClientId: AnyCodable = "testClientId"
        let testOrgId: AnyCodable = "testOrgId"
        let quickConnectService = QuickConnectService()
        let dataDict: [String: AnyCodable] = ["clientId": testClientId, "orgId": testOrgId, "deviceName": "testDeviceName"]
        let jsonData = try? JSONEncoder().encode(dataDict)
        let invalidResponse = HTTPURLResponse(url: URL(string: "https://adobe.com")!, statusCode: 404, httpVersion: nil, headerFields: nil)
        let expectedResponse = HttpConnection(data: jsonData, response: invalidResponse, error: nil)
        mockNetworkService.expectedResponse = expectedResponse
        let expectation = XCTestExpectation(description: "RegisterDevice API invokes completion handler with failedToRegisterDevice error")

        quickConnectService.deleteDevice(clientID: testClientId.stringValue!, orgID: testOrgId.stringValue!) { error in
            XCTAssertEqual(error, .failedToDeleteDevice(statusCode: 404, responseMessage: "not found"))
            XCTAssertTrue(self.mockNetworkService.connectAsyncCalled)
            XCTAssertEqual(self.mockNetworkService.networkRequest?.url, expectedUrl)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1.0)
    }

    func testDeleteDeviceFailureInvalidResponseData() {
        let expectedUrl = URL(string: AssuranceConstants.QUICK_CONNECT_BASE_URL + "/delete")!
        let testClientId: AnyCodable = "testClientId"
        let testOrgId: AnyCodable = "testOrgId"
        let quickConnectService = QuickConnectService()
        let validResponse = HTTPURLResponse(url: URL(string: "https://adobe.com")!, statusCode: 200, httpVersion: nil, headerFields: nil)
        let expectedResponse = HttpConnection(data: nil, response: validResponse, error: nil)
        mockNetworkService.expectedResponse = expectedResponse
        let expectation = XCTestExpectation(description: "RegisterDevice API invokes completion handler with invalid response data error")

        quickConnectService.deleteDevice(clientID: testClientId.stringValue!, orgID: testOrgId.stringValue!) { error in
            XCTAssertEqual(error, .invalidResponseData)
            XCTAssertTrue(self.mockNetworkService.connectAsyncCalled)
            XCTAssertEqual(self.mockNetworkService.networkRequest?.url, expectedUrl)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1.0)
    }


}
