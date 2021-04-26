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
import AEPCore
import AEPServices

class AssuranceState {
    
    private let datastore = NamedCollectionDataStore(name: AssuranceConstants.EXTENSION_NAME)
    
    var sessionId : String? {
        get {
            datastore.getString(key: AssuranceConstants.DataStoteKeys.SESSION_ID)
        }
        set {
            datastore.set(key: AssuranceConstants.DataStoteKeys.SESSION_ID, value: newValue)
        }
    }
    
    // getter for client ID
    lazy var clientID : String = {
        // check for client ID in persistence, if not create a UUID
        guard let persistedClientID = datastore.getString(key: AssuranceConstants.DataStoteKeys.CLIENT_ID) else {
            let newClientID = UUID().uuidString
            datastore.set(key: AssuranceConstants.DataStoteKeys.CLIENT_ID, value: newClientID)
            return newClientID
        }
        return persistedClientID
    }()
    
    
    func getSharedStateData() -> [String: String]? {
        // do not share shared state if the sessionId is unavailable
        guard let sessionId = sessionId else {
            return nil
        }
        
        var shareStateData : [String : String] = [:]
        shareStateData[AssuranceConstants.SharedStateKeys.CLIENT_ID] = clientID
        shareStateData[AssuranceConstants.SharedStateKeys.SESSION_ID] = sessionId
        shareStateData[AssuranceConstants.SharedStateKeys.INTEGRATION_ID] = clientID + "|" + sessionId
        return shareStateData
    }
    
}
