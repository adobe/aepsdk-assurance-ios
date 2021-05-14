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
import AEPCore
import Foundation

struct AssuranceEvent: Codable {
    var eventID: String = UUID().uuidString
    var vendor: String
    var type: String
    var payload: [String: AnyCodable]?
    var eventNumber: Int32?
    var timestamp: Int64?  // Todo : verify if this can rewritten as `Date` type

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
        if(event.timestamp == nil) {
            event.timestamp = Date().getUnixTimeInSeconds() * 1000
        }
        return event
    }
    
    /// TODO
    static func from(sdkEvent : Event) -> AssuranceEvent {
        var payload : [String : AnyCodable] = [:]
        payload[AssuranceConstants.ACPExtensionEventKey.NAME] = AnyCodable.init(sdkEvent.name)
        payload[AssuranceConstants.ACPExtensionEventKey.TYPE] = AnyCodable.init(sdkEvent.type)
        payload[AssuranceConstants.ACPExtensionEventKey.SOURCE] = AnyCodable.init(sdkEvent.source)
        payload[AssuranceConstants.ACPExtensionEventKey.UNIQUE_IDENTIFIER] = AnyCodable.init(sdkEvent.id)
        payload[AssuranceConstants.ACPExtensionEventKey.TIMESTAMP] = AnyCodable.init(sdkEvent.timestamp)
        
        // if available, add eventData
        if let eventData = sdkEvent.data {
            payload[AssuranceConstants.ACPExtensionEventKey.DATA] = AnyCodable.init(eventData)
        }
        
        // if available, add responseID
        if  let responseID = sdkEvent.responseID {
            payload[AssuranceConstants.ACPExtensionEventKey.RESPONSE_IDENTIFIER] = AnyCodable.init(responseID)
        }
                    
        return AssuranceEvent(type: AssuranceConstants.EventType.GENERIC, payload: payload)
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

    /// Returns the type of the control event. Applies only for control events. This method returns null for all other `AssuranceEvent` types.
    ///
    /// Returns nil if the event is not a control event.
    /// Returns nil if the payload does not contain "type" key.
    /// Returns nil if the payload "type" key contains non string data.
    ///
    /// Following are the available control events to the SDK.
    ///  * startEventForwarding
    ///  * screenshot
    ///  * logForwarding
    ///  * fakeEvent
    ///  * configUpdate
    ///
    /// - Returns: a string value representing the control type
    func getControlEventType() -> String? {
        if AssuranceConstants.EventType.CONTROL != type {
            return nil
        }

        return payload?[AssuranceConstants.PayloadKey.TYPE]?.stringValue
    }

    /// Returns the details of the control event. Applies only for control events. This method returns null for all other `AssuranceEvent` types.
    ///
    /// Returns nil if the event is not a control event.
    /// Returns nil if the payload does not contain "type" key.
    /// Returns nil if the payload "type" key contains non string data.
    ///
    /// - Returns: a dictionary representing the control details
    func getControlEventDetail() -> [String: Any]? {
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
    
    public var description: String {
        // swiftformat:disable indent
        return "\n[\n" +
                "  id: \(eventID)\n" +
                "  type: \(type)\n" +
                "  vendor: \(vendor)\n" +
                "  payload: \(PrettyDictionary.prettify(payload))\n" +
                "  eventNumber: \(String(describing: eventNumber))\n" +
                "  timestamp: \(String(describing: timestamp?.description))\n" +
                "]"
        // swiftformat:enable indent
    }

}
