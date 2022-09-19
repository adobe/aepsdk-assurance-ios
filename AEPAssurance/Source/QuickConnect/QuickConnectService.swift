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

import AEPServices
import Foundation
import UIKit

class QuickConnectService {
    var shouldRetryGetDeviceStatus = true
    typealias HTTP_RESPONSE_CODES = HttpConnectionConstants.ResponseCodes

    private let HEADERS = [HttpConnectionConstants.Header.HTTP_HEADER_KEY_ACCEPT: HttpConnectionConstants.Header.HTTP_HEADER_CONTENT_TYPE_JSON_APPLICATION,
                            HttpConnectionConstants.Header.HTTP_HEADER_KEY_CONTENT_TYPE: HttpConnectionConstants.Header.HTTP_HEADER_CONTENT_TYPE_JSON_APPLICATION]

    func registerDevice(clientID: String,
                        orgID: String,
                        completion: @escaping (AssuranceNetworkError?) -> Void) {

        /// Bail out with failure, if we are unable to form a valid create device API request URL
        guard let requestURL = URL(string: AssuranceConstants.QUICK_CONNECT_BASE_URL + "/create") else {
            let error = AssuranceNetworkError(message: "Create Device API - Unable to form the request URL. Please contact the Adobe Assurance SDK team for further assistance.")
            completion(error)
            return
        }

        let parameters = [AssuranceConstants.QuickConnect.KEY_ORGID: orgID,
                          AssuranceConstants.QuickConnect.KEY_DEVICE_NAME: UIDevice.current.name,
                          AssuranceConstants.QuickConnect.KEY_CLIENT_ID: clientID]

        /// Bail out with failure, if we are unable to create the request body required for the API
        guard let body = try? JSONSerialization.data(withJSONObject: parameters, options: .prettyPrinted) else {
            let error = AssuranceNetworkError(message: "Create Device API - Unable to form the request body. Please contact the Adobe Assurance SDK team for further assistance.")
            completion(error)
            return
        }

        /// Create the request
        let request = NetworkRequest(url: requestURL,
                                     httpMethod: HttpMethod.post,
                                     connectPayloadData: body,
                                     httpHeaders: HEADERS,
                                     connectTimeout: AssuranceConstants.Network.CONNECTION_TIMEOUT,
                                     readTimeout: AssuranceConstants.Network.READ_TIMEOUT)

        ServiceProvider.shared.networkService.connectAsync(networkRequest: request) { connection in

            if !(connection.responseCode == HTTP_RESPONSE_CODES.HTTP_OK || connection.responseCode == 201) {
                let error = AssuranceNetworkError(message: "Create Device API - Failed to register device, connection status code : \(connection.responseCode ?? -1) and error \(connection.responseMessage ?? "Unknown error")")
                completion(error)
                return
            }

            let responseJson = try? JSONDecoder().decode([String: AnyCodable].self, from: connection.data!)
            Log.debug(label: "Peaks", "Created device \(String(describing: responseJson))")

            completion(nil)
            return
        }
    }

    func getDeviceStatus(clientID: String,
                         orgID: String,
                         completion: @escaping (Result<(String, String), AssuranceNetworkError>) -> Void) {

        /// Bail out with failure, if we are unable to form a valid create device API request URL
        guard let requestURL = URL(string: AssuranceConstants.QUICK_CONNECT_BASE_URL + "/status") else {
            let error = AssuranceNetworkError(message: "Device Status API - Unable to form the request URL. Please contact the Adobe Assurance SDK team for further assistance.")
            completion(.failure(error))
            return
        }

        let parameters = [AssuranceConstants.QuickConnect.KEY_ORGID: orgID, AssuranceConstants.QuickConnect.KEY_CLIENT_ID: clientID]

        /// Bail out with failure, if we are unable to create the request body required for the API
        guard let body = try? JSONSerialization.data(withJSONObject: parameters, options: .prettyPrinted) else {
            let error = AssuranceNetworkError(message: "Device Status API - Unable to form the response body. Please contact the Adobe Assurance SDK team for further assistance.")
            completion(.failure(error))
            return
        }

        /// Create the request
        let request = NetworkRequest(url: requestURL,
                                     httpMethod: HttpMethod.post,
                                     connectPayloadData: body,
                                     httpHeaders: HEADERS,
                                     connectTimeout: AssuranceConstants.Network.CONNECTION_TIMEOUT,
                                     readTimeout: AssuranceConstants.Network.READ_TIMEOUT)

        ServiceProvider.shared.networkService.connectAsync(networkRequest: request) { connection in

            if !(connection.responseCode == HTTP_RESPONSE_CODES.HTTP_OK || connection.responseCode == 201) {
                let error = AssuranceNetworkError(message: "Create Device API - Failed to register device, connection status code : \(connection.responseCode ?? -1) and error \(connection.responseMessage ?? "Unknown error")")
                completion(.failure(error))
                return
            }

            if let data = connection.data, let responseDict = try? JSONDecoder().decode([String: AnyCodable].self, from: data) {
                let sessionID = responseDict["sessionUuid"]?.stringValue
                let token = responseDict["token"]?.intValue

                let status = try? JSONDecoder().decode([String: AnyCodable].self, from: connection.data!)
                Log.debug(label: "Peaks", "Device status \(String(describing: status))")
                guard let sessionID = sessionID, let token = token else {
                    if self.shouldRetryGetDeviceStatus {
                        sleep(2)
                        self.getDeviceStatus(clientID: clientID, orgID: orgID, completion: completion)
                    }
                    return
                }

                completion(.success((sessionID, String(token))))
                return
            }

            completion(.failure(AssuranceNetworkError(message: "Invalid response")))

            return
        }
    }

    func deleteDevice(clientID: String,
                      orgID: String,
                      completion: @escaping (AssuranceNetworkError?) -> Void) {

        /// Bail out with failure, if we are unable to form a valid create device API request URL
        guard let requestURL = URL(string: AssuranceConstants.QUICK_CONNECT_BASE_URL + "/delete") else {
            let error = AssuranceNetworkError(message: "Create Device API - Unable to form the request URL. Please contact the Adobe Assurance SDK team for further assistance.")
            completion(error)
            return
        }

        let parameters = [AssuranceConstants.QuickConnect.KEY_ORGID: orgID,
                          AssuranceConstants.QuickConnect.KEY_DEVICE_NAME: UIDevice.current.name,
                          AssuranceConstants.QuickConnect.KEY_CLIENT_ID: clientID]

        /// Bail out with failure, if we are unable to create the request body required for the API
        guard let body = try? JSONSerialization.data(withJSONObject: parameters, options: .prettyPrinted) else {
            let error = AssuranceNetworkError(message: "Create Device API - Unable to form the request body. Please contact the Adobe Assurance SDK team for further assistance.")
            completion(error)
            return
        }

        /// Create the request
        let request = NetworkRequest(url: requestURL,
                                     httpMethod: HttpMethod.post,
                                     connectPayloadData: body,
                                     httpHeaders: HEADERS,
                                     connectTimeout: AssuranceConstants.Network.CONNECTION_TIMEOUT,
                                     readTimeout: AssuranceConstants.Network.READ_TIMEOUT)

        ServiceProvider.shared.networkService.connectAsync(networkRequest: request) { connection in

            if !(connection.responseCode == HTTP_RESPONSE_CODES.HTTP_OK || connection.responseCode == 201) {
                let error = AssuranceNetworkError(message: "Create Device API - Failed to register device, connection status code : \(connection.responseCode ?? -1) and error \(connection.responseMessage ?? "Unknown error")")
                completion(error)
                return
            }

            let responseJson = try? JSONDecoder().decode([String: AnyCodable].self, from: connection.data!)
            Log.debug(label: "Peaks", "Created device \(String(describing: responseJson))")

            completion(nil)
            return
        }
    }

}

struct AssuranceNetworkError: Error {
    let message: String
}
