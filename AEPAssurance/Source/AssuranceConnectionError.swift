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

// todo later: For better clarity separate out into two enums .. socketError vs clientSideError for socket connection
enum AssuranceConnectionError: Error, Equatable {
    case genericError
    case noOrgId
    case noPincode
    case orgIDMismatch
    case connectionLimit
    case eventLimit
    case deletedSession
    case clientError
    case invalidURL(url: String)
    case invalidRequest
    case invalidResponse
    case requestFailed

    var info: (name: String, description: String, shouldRetry: Bool) {
        switch self {
        case .genericError:
            return (NSLocalizedString("error_title_incorrect_pin_or_network", value: "Connection Error", comment: ""), NSLocalizedString("error_desc_incorrect_pin_or_network", value: "The connection may be failing due to a network issue or an incorrect PIN. Please verify internet connectivity or the PIN and try again." , comment: ""), true)
        case .noPincode:
            return (NSLocalizedString("error_title_invalid_pin", value: "Authorization Error", comment: ""),
                    NSLocalizedString("error_desc_invalid_pin", value: "Unable to authorize Assurance connection. Please verify the PIN and try again.", comment: ""), true)
        case .noOrgId:
            return (NSLocalizedString("error_title_invalid_org_id", value: "Invalid Mobile SDK Configuration", comment: ""),
                    NSLocalizedString("error_desc_invalid_org_id", value: "The Experience Cloud organization identifier is unavailable. Ensure SDK configuration is setup correctly. See documentation for more detail.", comment: ""), false)
        case .orgIDMismatch:
            return (NSLocalizedString("error_title_unauthorized_access", value: "Unauthorized Access", comment: ""),
                    NSLocalizedString("error_desc_unauthorized_access", value: "The Experience Cloud organization identifier does not match with that of the Assurance session. Ensure the right Experience Cloud organization is being used. See documentation for more detail.", comment: ""), false)
        case .connectionLimit:
            return (NSLocalizedString("error_title_connection_limit", value: "Connection Limit Reached", comment: ""),
                    NSLocalizedString("error_desc_connection_limit", value: "You have reached the maximum number of connected device allowed to a session.", comment: ""), false)
        case .eventLimit:
            return (NSLocalizedString("error_title_event_limit", value: "Event Limit Reached", comment: ""),
                    NSLocalizedString("error_desc_event_limit", value: "You have reached the maximum number of events that can be sent per minute.", comment: ""), false)
        // todo immediate:  check with the team on better description.
        // todo later:  have griffon server return error description and how to solve... Same for connection & event limit errors
        case .deletedSession:
            return (NSLocalizedString("error_title_session_deleted", value: "Session Deleted", comment: ""),
                    NSLocalizedString("error_desc_session_deleted", value: "You attempted to connect to a deleted session.", comment: ""), false)
        case .clientError:
            return (NSLocalizedString("error_title_unexpected_error", value: "Client Disconnected", comment: ""),
                    NSLocalizedString("", value: "This client has been disconnected due to an unexpected error.", comment: ""), false)
        case .invalidURL(let url):
            return (NSLocalizedString("error_title_invalid_url", value: "Invalid url", comment: ""),
                    NSLocalizedString("error_desc_invalid_url", value: "Attempted a network request with an invalid url.", comment: ""), false)
        case .invalidResponse:
            return (NSLocalizedString("error_title_invalid_registration_response", value: "Invalid response data", comment: ""),
                    NSLocalizedString("error_desc_invalid_registration_response", value: "Connection failed due to an invalid response.", comment: ""), false)
        case .invalidRequest:
            return (NSLocalizedString("error_title_invalid_registration_request", value: "Connection Error", comment: ""),
                    NSLocalizedString("error_desc_invalid_registration_request", value: "The connection may be failing due to an invalid network request.", comment: ""), false)
        case .requestFailed:
            return (NSLocalizedString("error_title_registration_error", value: "Connection Error", comment: ""),
                    NSLocalizedString("error_desc_registration_error", value: "Error occurred during device registration or status check.", comment: ""), false)
        }
    }
}
