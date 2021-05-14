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

extension AssuranceSession : SocketDelegate {
    func webSocket(_ socket: SocketConnectable, didReceiveEvent event: AssuranceEvent) {
        Log.trace(label: AssuranceConstants.LOG_TAG, "Received event from assurance session - \(event.description)")
        guard let controlType = event.getControlEventType() else {
            Log.debug(label: AssuranceConstants.LOG_TAG, "A non control event is received event from assurance session. Ignoring to process event - \(event.description)")
            return
        }
        
        if (AssuranceConstants.CommandType.START_EVENT_FORWARDING == controlType) {
            canStartForwarding = true
            // On reception of the startForwarding event
            // 1. Remove the WebView UI and display the floating button
            // 2. Share the Assurance shared state
            // 3. Notify the client plugins on successful connection
            pinCodeScreen?.connectionSucceeded()
            statusUI?.display()
            pluginCollection.notifyPluginsOnConnect()
            outboundSource.add(data: 1)
            return
        }
                
        inboundQueue.enqueue(newElement: event)
        inboundSource.add(data: 1)
    }
    
    func webSocketDidConnect(_ socket: SocketConnectable) {
        Log.debug(label: AssuranceConstants.LOG_TAG, "Assurance session successfully connected.")
        self.sendClientInfoEvent()
    }
    
    func webSocketDidDisconnectConnect(_ socket: SocketConnectable, _ closeCode: Int, _ reason: String, _ wasClean: Bool) {
        
    }
    
    func webSocketOnError(_ socket: SocketConnectable) {
        
    }
    
    func webSocket(_ socket: SocketConnectable, didReceiveMessage message: Data) {
        
    }
    
    func webSocket(_ socket: SocketConnectable, didChangeState state: SocketState) {
    
    }
}

