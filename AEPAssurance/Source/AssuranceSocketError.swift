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

enum AssuranceSocketError {
    case GENERIC_ERROR
    case NO_ORG_ID
    case NO_SESSION_ID
    case NO_PINCODE
    case ORGID_MISMATCH
    case CONNECTION_LIMIT
    case EVENT_LIMIT
    case CLIENT_ERROR

    var info: (name: String, description: String) {
        switch self {
        case .GENERIC_ERROR:
            return ("Connection Error",
                    "The connection may be failing due to a network issue or an incorrect PIN. Please verify internet connectivity or the PIN and try again.")
        case .NO_SESSION_ID:
            return ("Invalid SessionID",
                    "Unable to extract valid Assurance sessionID from deeplink URL. Please try re-connecting to the session with a valid deeplink URL")
        case .NO_PINCODE:
            return ("HTML Error",
                    "Unable to extract the pincode entered.")
        case .NO_ORG_ID:
            return ("Invalid Launch & SDK Configuration",
                    "The Experience Cloud Org identifier is unavailable from SDK configuration. Please ensure the Launch mobile property is properly configured.")
        case .ORGID_MISMATCH:
            return ("Unauthorized Access",
                    "The Experience Cloud organization for this Launch Property does not match that of the AEP Assurance session")
        case .CONNECTION_LIMIT:
            return ("Connection Limit Reached",
                    "You have reached the maximum number of connected device (50) allowed to a session.")
        case .EVENT_LIMIT:
            return ("Event Limit Reached",
                    "You have reached the maximum number of events (10k) that can be sent per minute.")
        case .CLIENT_ERROR:
            return ("Client Disconnected",
                    "This client has been disconnected due to an unexpected error. Error Code 4400.")
        }
    }
}
