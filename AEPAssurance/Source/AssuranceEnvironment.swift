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

/// Represents a griffon server environment to which a session attempts to connect.
enum AssuranceEnvironment: String {
    case prod = ""
    case qa = "qa"
    case stage = "stage"
    case dev = "dev"

    var urlFormat: String {
        switch self {
        case .prod:
            return AssuranceConstants.AssuranceEnvironmentURLFormat.PRODUCTION
        case .qa:
            return AssuranceConstants.AssuranceEnvironmentURLFormat.QA
        case .stage:
            return AssuranceConstants.AssuranceEnvironmentURLFormat.STAGE
        case .dev:
            return AssuranceConstants.AssuranceEnvironmentURLFormat.DEV
        }
    }
    /// Initializer that converts a `String` to its respective `AssuranceEnvironment`
    /// If `envString` is not a valid `AssuranceEnvironment`, calling this method will return `AssuranceEnvironment.prod`
    /// - Parameter envString: a `String` representation of a `AssuranceEnvironment`
    /// - Returns: a `AssuranceEnvironment` representing the passed-in `String`
    init(envString: String){
        self = AssuranceEnvironment(rawValue: envString) ?? .prod
    }

}
