//
// Copyright 2022 Adobe. All rights reserved.
// This file is licensed to you under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License. You may obtain a copy
// of the License at http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software distributed under
// the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR REPRESENTATIONS
// OF ANY KIND, either express or implied. See the License for the specific language
// governing permissions and limitations under the License.
//

import AEPServices
import Foundation

class AssuranceSessionDetails {

    private let SESSION_ID_KEY = "sessionId"
    private let PINCODE_KEY = "token"
    private let CLIENT_ID_KEY = "clientId"
    private let ORGID_KEY = "orgId"

    let datastore = NamedCollectionDataStore(name: AssuranceConstants.EXTENSION_NAME)
    let sessionId: String
    let environment: AssuranceEnvironment!
    let clientID: String
    var pinCode: String?
    var orgId: String?

    init(sessionId: String, clientId: String, environment: AssuranceEnvironment = AssuranceEnvironment.prod) {
        self.sessionId = sessionId
        self.clientID = clientId
        self.environment = environment
    }

    init(withURLString socketURLString: String) throws {

        guard let socketURL = URL(string: socketURLString) else {
            throw AssuranceSessionDetailBuilderError(message: "Not a vaild URL")
        }

        guard let sessionId = socketURL.params[SESSION_ID_KEY] else {
            throw AssuranceSessionDetailBuilderError(message: "No SessionId")
        }

        guard let clientId = socketURL.params[CLIENT_ID_KEY] else {
            throw AssuranceSessionDetailBuilderError(message: "No ClientId")
        }

        guard let orgId = socketURL.params[ORGID_KEY] else {
            throw AssuranceSessionDetailBuilderError(message: "No OrgId")
        }

        guard let pinCode = socketURL.params[PINCODE_KEY] else {
            throw AssuranceSessionDetailBuilderError(message: "No PinCode")
        }

        guard let host = socketURL.host else {
            throw AssuranceSessionDetailBuilderError(message: "URL has no host")
        }

        self.sessionId = sessionId
        self.clientID = clientId
        self.orgId = orgId
        self.pinCode = pinCode
        self.environment = AssuranceSessionDetails.readEnvironment(fromHost: host)
    }

    func getAuthenticatedSocketURL() -> Result<URL, AssuranceSessionDetailAuthenticationError> {
        guard let pin = pinCode else {
            return .failure(.noPinCode)
        }

        guard let orgId = orgId else {
            return .failure(.noOrgId)
        }

        // wss://connect%@.griffon.adobe.com/client/v1?sessionId=%@&token=%@&orgId=%@&clientId=%@
        let socketURL = String(format: AssuranceConstants.BASE_SOCKET_URL,
                               environment.urlFormat,
                               sessionId,
                               pin,
                               orgId,
                               clientID)

        guard let url = URL(string: socketURL) else {
            return .failure(.invalidURL)
        }
        return .success(url)
    }

    func authenticate(withPIN pinCode: String, andOrgID orgId: String) {
        self.pinCode = pinCode
        self.orgId = orgId
    }

    private static func readEnvironment(fromHost host: String) -> AssuranceEnvironment {

        guard let connectString = host.split(separator: ".").first else {
            return .prod
        }

        if connectString.split(separator: "-").indices.contains(1) {
            let environmentString = connectString.split(separator: "-")[1]
            return AssuranceEnvironment(envString: String(environmentString))
        }
        return .prod
    }
}

struct AssuranceSessionDetailBuilderError: Error {
    let message: String
}

enum AssuranceSessionDetailAuthenticationError: Error {
    case noPinCode
    case noOrgId
    case invalidURL
}
