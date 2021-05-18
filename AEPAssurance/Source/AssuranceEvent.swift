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

struct AssuranceEvent: Codable {
    var eventID: String = UUID().uuidString
    var vendor: String
    var type: String
    var payload: [String: AnyCodable]?
    var eventNumber: Int32?
    var timestamp: Int64  // Todo : verify if this can rewritten as `Date` type

    /// Decodes a JSON data into a `AssuranceEvent`
    ///
    /// The following keys are required in the provided JSON:
    ///      - eventID - A unique UUID string to identify the event
    ///      - vendor - A vendor string
    ///      - type - A string describing the type of the event
    ///      - timestamp - A whole number representing milliseconds since the Unix epoch
    ///      - payload (optional) - A JSON object containing the event's payload
    ///
    /// This method will return nil if called under any of the following conditions:
    ///      - The provided json is not valid
    ///      - The provided json is not an object at its root
    ///      - Any of the required keys are missing (see above for a list of required keys)
    ///      - Any of the required keys do not contain the correct type of data
    ///
    /// - Parameters:
    ///   - jsonData: jsonData representing `AssuranceEvent`
    ///
    /// - Returns: a `AssuranceEvent` that is represented in the json data, nil if data is not in the correct format
    static func from(jsonData: Data) -> AssuranceEvent? {
        guard var event = try? JSONDecoder().decode(AssuranceEvent.self, from: jsonData) else {
            Log.debug(label: AssuranceConstants.LOG_TAG, "Unable to decode jsonData into an AssuranceEvent.")
            return nil
        }
        event.eventNumber = AssuranceEvent.generateEventNumber()
        return event
    }

    /// Initializer to construct `AssuranceEvent`instance with the given parameters
    ///
    /// - Parameters:
    ///   - type: a String describing the type of AssuranceEvent
    ///   - payload: A dictionary representing the payload to be sent wrapped in the event. This will be serialized into JSON in the transportation process
    ///   - timestamp: optional argument representing the time original event was created. If not provided current time is taken
    ///   - vendor: vendor for the created `AssuranceEvent` defaults to "com.adobe.griffon.mobile".
    init(type: String, payload: [String: AnyCodable]?, timestamp: Int64 = (Date().getUnixTimeInSeconds() * 1000), vendor: String = AssuranceConstants.Vendor.MOBILE) {
        self.type = type
        self.payload = payload
        self.timestamp = timestamp
        self.vendor = vendor
        self.eventNumber = AssuranceEvent.generateEventNumber()
    }

    /// Returns the type of the command. Applies only for command events. This method returns nil for all other `AssuranceEvent`s.
    ///
    /// Returns nil if the event is not a command event.
    /// Returns nil if the payload does not contain "type" key.
    /// Returns nil if the payload "type" key contains non string data.
    ///
    /// Following are the currently available command recognized by Assurance SDK.
    ///  * startEventForwarding
    ///  * screenshot
    ///  * logForwarding
    ///  * fakeEvent
    ///  * configUpdate
    ///
    ///  Note : Commands are `AssuranceEvent` with type "control".
    ///  They are usually events generated from the Griffon UI demanding a specific action at the mobile client.
    ///
    /// - Returns: a string value representing the command (or) control type
    var commandType: String? {
        if AssuranceConstants.EventType.CONTROL != type {
            return nil
        }

        return payload?[AssuranceConstants.PayloadKey.TYPE]?.stringValue
    }

    /// Returns the details of the command. Applies only for command events. This method returns nil for all other `AssuranceEvent`s.
    ///
    /// Returns nil if the event is not a command event.
    /// Returns nil if the payload does not contain "type" key.
    /// Returns nil if the payload "type" key contains non string data.
    ///
    /// Note : Commands are `AssuranceEvent` with type "control".
    /// They are usually events generated from the Griffon UI demanding a specific action at the mobile client.
    ///
    /// - Returns: a dictionary representing the command details
    var commandDetails: [String: Any]? {
        if AssuranceConstants.EventType.CONTROL != type {
            return nil
        }

        return payload?[AssuranceConstants.PayloadKey.DETAIL]?.dictionaryValue
    }

    static private var eventNumberCounter: Int32 = 0
    private static func generateEventNumber() -> Int32 {
        OSAtomicIncrement32(&eventNumberCounter)
        return eventNumberCounter
    }

}
