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

class PluginScreenShotTests: XCTestCase {

    var plugin = PluginScreenshot()
    let runtime = TestableExtensionRuntime()
    var mockUIUtil = MockAssuranceUIUtil()
    var mockNetworkService = MockNetworkService()
    var mockStateManager: MockStateManager?
    var mockSession: MockSession!
    var screenShotEvent = AssuranceEvent.init(type: AssuranceConstants.EventType.CONTROL, payload: nil)

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

    let sampleImageData = "PhoneImage".data(using: .utf8)!

    override func setUpWithError() throws {
        mockStateManager = MockStateManager(runtime)
        let mockSessionOrchestrator = MockSessionOrchestrator(stateManager: mockStateManager!)
        let sessionDetail = AssuranceSessionDetails(sessionId: "mocksessionId", clientId: "clientId", environment: .dev)
        mockSession = MockSession(sessionDetails: sessionDetail, stateManager: mockStateManager!, sessionOrchestrator: mockSessionOrchestrator, outboundEvents: nil)
        ServiceProvider.shared.networkService = mockNetworkService
        plugin.uiUtil = mockUIUtil
    }

    func test_vendor() {
        XCTAssertEqual(AssuranceConstants.Vendor.MOBILE, plugin.vendor)
    }

    func test_commandType() {
        XCTAssertEqual(AssuranceConstants.CommandType.SCREENSHOT, plugin.commandType)
    }

    func test_commandScreenshot() {
        // setup
        mockUIUtil.mockImageData = sampleImageData
        plugin.onRegistered(mockSession)

        // test
        plugin.receiveEvent(screenShotEvent)

        // verify the network call is made
        XCTAssertTrue(mockNetworkService.connectAsyncCalled)

        // now mock the network response
        let mockConnection = HttpConnection.init(data: sampleResponse, response: HTTPURLResponse.init(), error: nil)
        mockNetworkService.completionHandler!(mockConnection)

        // verify that the assurance event is sent to the socket
        wait(for: [mockSession.sendEventCalled], timeout: 1.0)
        XCTAssertEqual("mockBlobId", mockSession.sentEvent?.payload?["blobId"])
        XCTAssertEqual("image/png", mockSession.sentEvent?.payload?["mimeType"])
    }

    func test_commandScreenshot_whenAssuranceSessionNotAvailable() {
        // setup
        mockUIUtil.mockImageData = sampleImageData
        // not calling plugin.onRegistered() will not set the session variable in PluginScreenShot

        // test
        plugin.receiveEvent(screenShotEvent)

        // verify the network call is not made
        XCTAssertFalse(mockNetworkService.connectAsyncCalled)
    }

    func test_commandScreenshot_whenDeviceFailsToCaptureScreenshot() {
        // setup
        mockUIUtil.mockImageData = nil
        plugin.onRegistered(mockSession)

        // test
        plugin.receiveEvent(screenShotEvent)

        // verify the network call is not made
        XCTAssertFalse(mockNetworkService.connectAsyncCalled)
    }

    func test_commandScreenshot_whenUploadingFails() {
        // setup
        mockUIUtil.mockImageData = sampleImageData
        plugin.onRegistered(mockSession)
        
        mockSession.sendEventCalled.isInverted = true

        // test
        plugin.receiveEvent(screenShotEvent)

        // verify the network call is made
        XCTAssertTrue(mockNetworkService.connectAsyncCalled)

        // now mock error network response
        let mockConnection = HttpConnection.init(data: errorResponse, response: HTTPURLResponse.init(), error: nil)
        mockNetworkService.completionHandler!(mockConnection)

        // verify that the assurance event is not sent
        wait(for: [mockSession.sendEventCalled], timeout: 1.0)
    }

}
