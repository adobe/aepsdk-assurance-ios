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
import AEPCore

struct PluginFakeEvent : AssurancePlugin {
        
    var vendor: String = AssuranceConstants.Vendor.MOBILE
    
    var commandType: String = AssuranceConstants.CommandType.FAKE_EVENT
    
    func receiveEvent(_ event: AssuranceEvent) {
        guard let controlDetails = event.getControlEventDetail() else {
            Log.debug(label: AssuranceConstants.LOG_TAG, "Payload control details is empty. Assurance SDK is ignoring the fake event dispatch command.")
            return
        }
        
        // extract the details of the fake event from the Assurance event's payload
        // 1. Read the event name
        guard let eventName = controlDetails[AssuranceConstants.SDKEventKey.NAME] as? String else {
            Log.debug(label: AssuranceConstants.LOG_TAG, "Event name is null or not a string in the payload. Assurance SDK is ignoring the fake event dispatch command.")
            return
        }
        
        // 2. Read event source
        guard let eventSource = controlDetails[AssuranceConstants.SDKEventKey.SOURCE] as? String else {
            Log.debug(label: AssuranceConstants.LOG_TAG, "Event source is null or not a string in the payload. Assurance SDK is ignoring the fake event dispatch command.")
            return
        }
        
        // 3. Read event type
        guard let eventType = controlDetails[AssuranceConstants.SDKEventKey.TYPE] as? String else {
            Log.debug(label: AssuranceConstants.LOG_TAG, "Event type is null or not a string in the payload. Assurance SDK is ignoring the fake event dispatch command.")
            return
        }
                    
        let fakeEvent = Event(name: eventName, type: eventType, source: eventSource, data: controlDetails[AssuranceConstants.SDKEventKey.DATA] as? [String : Any])
        MobileCore.dispatch(event: fakeEvent)
    }
        
    // no op - protocol methods
    func onRegistered(_ session: AssuranceSession) {}
        
    func onSessionConnected() {}
    
    func onSessionDisconnectedWithCloseCode(_ closeCode: Int) {}
    
    func onSessionTerminated() {}
        
}
