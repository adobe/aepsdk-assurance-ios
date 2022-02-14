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

    var shouldContinueChecking = true
    private let KEY_ORGID = "orgId"
    private let KEY_DEVICE_NAME = "deviceName"
    private let KEY_CLIENT_ID = "clientId"
    typealias HTTP_RESPONSE_CODES = HttpConnectionConstants.ResponseCodes

    private let HEADERS = [HttpConnectionConstants.Header.HTTP_HEADER_KEY_ACCEPT: HttpConnectionConstants.Header.HTTP_HEADER_CONTENT_TYPE_JSON_APPLICATION,
                            HttpConnectionConstants.Header.HTTP_HEADER_KEY_CONTENT_TYPE: HttpConnectionConstants.Header.HTTP_HEADER_CONTENT_TYPE_JSON_APPLICATION]

    func registerDevice(clientID: String,
                        orgID: String,
                        callback: @escaping (Result<Bool, AssuranceNetworkError>) -> Void) {

        /// Bail out with failure, if we are unable to form a valid create device API request URL
        guard let requestURL = URL(string: AssuranceConstants.QUICK_CONNECT_BASE_URL + "/create") else {
            let error = AssuranceNetworkError(message: "Create Device API - Unable to form the request URL. Please contact the Adobe Assurance SDK team for further assistance.")
            callback(.failure(error))
            return
        }

        let parameters = [KEY_ORGID: orgID,
                          KEY_DEVICE_NAME: UIDevice.current.name,
                          KEY_CLIENT_ID: clientID]

        /// Bail out with failure, if we are unable to create the request body required for the API
        guard let body = try? JSONSerialization.data(withJSONObject: parameters, options: .prettyPrinted) else {
            let error = AssuranceNetworkError(message: "Create Device API - Unable to form the request body. Please contact the Adobe Assurance SDK team for further assistance.")
            callback(.failure(error))
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
                callback(.failure(error))
                return
            }

            let responseJson = try? JSONDecoder().decode([String: AnyCodable].self, from: connection.data!)
            Log.debug(label: "Peaks", "Created device \(String(describing: responseJson))")

            callback(.success(true))
            return
        }
    }

    func getDeviceStatus(clientID: String,
                         orgID: String,
                         callback: @escaping (Result<(String, String), AssuranceNetworkError>) -> Void) {

        /// Bail out with failure, if we are unable to form a valid create device API request URL
        guard let requestURL = URL(string: AssuranceConstants.QUICK_CONNECT_BASE_URL + "/status") else {
            let error = AssuranceNetworkError(message: "Device Status API - Unable to form the request URL. Please contact the Adobe Assurance SDK team for further assistance.")
            callback(.failure(error))
            return
        }

        let parameters = [KEY_ORGID: orgID, KEY_CLIENT_ID: clientID]

        /// Bail out with failure, if we are unable to create the request body required for the API
        guard let body = try? JSONSerialization.data(withJSONObject: parameters, options: .prettyPrinted) else {
            let error = AssuranceNetworkError(message: "Device Status API - Unable to form the response body. Please contact the Adobe Assurance SDK team for further assistance.")
            callback(.failure(error))
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
                callback(.failure(error))
                return
            }

            if let data = connection.data, let responseDict = try? JSONDecoder().decode([String: AnyCodable].self, from: data) {
                let sessionID = responseDict["sessionUuid"]?.stringValue
                let token = responseDict["token"]?.intValue

                let status = try? JSONDecoder().decode([String: AnyCodable].self, from: connection.data!)
                Log.debug(label: "Peaks", "Device status \(String(describing: status))")
                guard let sessionID = sessionID, let token = token else {
                    sleep(2)
                    self.getDeviceStatus(clientID: clientID, orgID: orgID, callback: callback)
                    return
                }

                callback(.success((sessionID, String(token))))
                return
            }

            callback(.failure(AssuranceNetworkError(message: "Invalid response")))

            return
        }
    }

    func deleteDevice(clientID: String,
                      orgID: String,
                      callback: @escaping (Result<Bool, AssuranceNetworkError>) -> Void) {

        /// Bail out with failure, if we are unable to form a valid create device API request URL
        guard let requestURL = URL(string: AssuranceConstants.QUICK_CONNECT_BASE_URL + "/delete") else {
            let error = AssuranceNetworkError(message: "Create Device API - Unable to form the request URL. Please contact the Adobe Assurance SDK team for further assistance.")
            callback(.failure(error))
            return
        }

        let parameters = [KEY_ORGID: orgID,
                          KEY_DEVICE_NAME: UIDevice.current.name,
                          KEY_CLIENT_ID: clientID]

        /// Bail out with failure, if we are unable to create the request body required for the API
        guard let body = try? JSONSerialization.data(withJSONObject: parameters, options: .prettyPrinted) else {
            let error = AssuranceNetworkError(message: "Create Device API - Unable to form the request body. Please contact the Adobe Assurance SDK team for further assistance.")
            callback(.failure(error))
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
                callback(.failure(error))
                return
            }

            let responseJson = try? JSONDecoder().decode([String: AnyCodable].self, from: connection.data!)
            Log.debug(label: "Peaks", "Created device \(String(describing: responseJson))")

            callback(.success(true))
            return
        }
    }

}

struct AssuranceNetworkError: Error {
    let message: String
}
