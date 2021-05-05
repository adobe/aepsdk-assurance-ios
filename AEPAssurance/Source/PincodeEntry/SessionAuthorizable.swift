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

import Foundation

protocol SessionAuthorizable {
    typealias callback = (String) -> Void

    init(withExtension: Assurance)

    /// Invoke this during start session to display the pinCode screen
    mutating func getSocketURL(callback : @escaping callback)

    /// Invoked when the a socket connection is initialized
    func connectionInitialized()

    /// Invoked when the a successful socket connection is established with a desired assurance session
    func connectionSucceeded()

    /// Invoked when the a successful socket connection is terminated
    func connectionFinished()

    /// Invoked when the a socket connection is failed
    /// - Parameters
    ///     - error - an `AssuranceSocketError` explaining the reason why the connection failed
    ///     - shouldShowRetry - boolean indication if the retry button on the pinpad button should still be shown
    func connectionFailedWithError(_ error: AssuranceSocketError, shouldShowRetry: Bool)
}
