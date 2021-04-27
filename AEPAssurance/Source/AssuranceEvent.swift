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
import AEPServices

struct AssuranceEvent : Codable {
    var eventID : String = UUID().uuidString
    var vendor : String
    var type : String
    var payload : [String: AnyCodable]?
    var eventNumber : Int32?
    var timestamp : Int64

    /// Decodes a [String: Any] dictionary into a `ConsentPreferences`
    /// - Parameter data: the event data representing `ConsentPreferences`
    /// - Returns: a `ConsentPreferences` that is represented in the event data, nil if data is not in the correct format
    static func from(jsonData: Data) -> AssuranceEvent? {
        guard var event = try? JSONDecoder().decode(AssuranceEvent.self, from: jsonData) else {
            Log.debug(label: AssuranceConstants.LOG_TAG, "Unable to decode jsonData into an AssuranceEvent.")
            return nil
        }
        event.eventNumber = AssuranceEvent.generateEventNumber()
        return event
    }
    
    init(type : String, payload : [String : AnyCodable]?, timestamp : Int64 = (Date().getUnixTimeInSeconds() * 1000), vendor : String = AssuranceConstants.Vendor.MOBILE) {
        self.type = type
        self.payload = payload
        self.timestamp = timestamp
        self.vendor = vendor
        self.eventNumber = AssuranceEvent.generateEventNumber()
    }
    
    func getControlEventType() -> String? {
        if (AssuranceConstants.EventType.CONTROL != type){
            return nil
        }
        
        guard let controlType = payload?[AssuranceConstants.PayloadKey.TYPE]?.stringValue else{
            return nil
        }
        
        return controlType;
    }
    
    func getControlEventDetail() -> [String:Any]? {
        if (AssuranceConstants.EventType.CONTROL != type){
            return nil
        }
        
        guard let controlDetail = payload?[AssuranceConstants.PayloadKey.DETAIL]?.dictionaryValue else{
            return nil
        }
        
        return controlDetail;
    }
    
    static private var eventNumberCounter : Int32 = 0
    private static func generateEventNumber() -> Int32 {
        OSAtomicIncrement32(&eventNumberCounter)
        return eventNumberCounter
    }

}

