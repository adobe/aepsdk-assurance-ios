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

struct AssurancePluginCollection {
    let pluginCollection = ThreadSafeDictionary<Int, ThreadSafeArray<AssurancePlugin>>(identifier: "com.adobe.assurance.pluginCollection")
    
    func addPlugin(_ plugin : AssurancePlugin, toSession session : AssuranceSession) {
        
        let vendorHash = plugin.vendor.hash
        
        var pluginVendorArray = pluginCollection[vendorHash]
        
        if (pluginVendorArray == nil) {
            pluginVendorArray = ThreadSafeArray<AssurancePlugin>()
        }
        
        pluginVendorArray?.append(plugin)
        plugin.onRegistered(session)
    }
    
    
    func notifyPluginsOfEvent(_ event: AssuranceEvent) {
        guard let pluginsForVendor = pluginCollection[event.vendor.hash] else {
            return
        }
    
        for i in 0...pluginsForVendor.count {
            let plugin = pluginsForVendor[i]
            
            // if the plugin matches control type of the event. Send the event to that plugin
            if (plugin.commandType.lowercased() == AssuranceConstants.CommandType.WILDCARD || plugin.commandType.lowercased() == event.getControlEventType()) {
                plugin.receiveEvent(event)
            }
        }
    }
        
    
    func notifyPluginsOnConnect() {
        getEachRegisteredPlugin({ plugin in
            plugin.onSessionConnected()
        })
    }
    
    func notifyPluginsOnDisconnect(withCloseCode closeCode : Int) {
        getEachRegisteredPlugin({ plugin in
            plugin.onSessionDisconnectedWithCloseCode(closeCode)
        })
    }
    
    func notifyPluginsOnSessionTerminated() {
        getEachRegisteredPlugin({ plugin in
            plugin.onSessionTerminated()
        })
    }
    
    private func getEachRegisteredPlugin(_ callback : (AssurancePlugin)-> Void) {
//        for pluginVendor in pluginCollection.allKeys {
//            guard let threadSafePluginsArray = pluginCollection[pluginVendor] else {
//                return
//            }
//
//            for i in 0...threadSafePluginsArray.count {
//                let plugin = threadSafePluginsArray[i]
//                callback(plugin)
//            }
//        }
    }
    

}
