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


struct PluginConfigUpdate : AssurancePlugin {
    
    let datastore = NamedCollectionDataStore(name: AssuranceConstants.EXTENSION_NAME)
        
    var vendor: String = AssuranceConstants.Vendor.MOBILE
    
    var commandType: String = AssuranceConstants.CommandType.UPDATE_CONFIG
    
    func receiveEvent(_ event: AssuranceEvent) {
        guard let controlDetails = event.getControlEventDetail() else {
            Log.debug(label: AssuranceConstants.LOG_TAG, "Payload control details empty. Assurance SDK is ignoring the command to update configuration.")
            return
        }
        
        MobileCore.updateConfigurationWith(configDict: controlDetails)
        saveModifiedKeys(Array(controlDetails.keys))
    }
        
    // no op - protocol methods
    func onRegistered(_ session: AssuranceSession) {
        
    }
    
    func onSessionConnected() {
        
    }
    
    func onSessionDisconnectedWithCloseCode(_ closeCode: Int) {
        
    }
    
    func onSessionTerminated() {
        
    }
    
    private func saveModifiedKeys(_ newKeys : [String]) {
        let savedKeys = datastore.getArray(key: AssuranceConstants.DataStoreKeys.CONFIG_MODIFIED_KEYS, fallback: [])
        var saveKeyStrings: [String] = savedKeys!.compactMap { String(describing: $0) }

        for eachkey in saveKeyStrings {
            
        }
        
    }
        
}
