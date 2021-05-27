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

import AEPServices
import Foundation

public class MockNetworkService: Networking {
    public var connectAsyncCalled: Bool = false
    public var networkRequest: NetworkRequest?
    public var completionHandler: ((HttpConnection) -> Void)?
    public var expectedResponse: HttpConnection?

    public init() {}

    public func connectAsync(networkRequest: NetworkRequest, completionHandler: ((HttpConnection) -> Void)? = nil) {
        connectAsyncCalled = true
        self.networkRequest = networkRequest
        self.completionHandler = completionHandler
        if let expectedResponse = expectedResponse, let completionHandler = completionHandler {
            completionHandler(expectedResponse)
        }
    }

    public func reset() {
        connectAsyncCalled = false
        networkRequest = nil
        completionHandler = nil
    }
}
