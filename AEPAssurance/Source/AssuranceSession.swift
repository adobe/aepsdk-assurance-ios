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

class AssuranceSession {
    
    let assuranceExtension: Assurance
    var pinCodeScreen: SessionAuthorizable?
    let outboundQueue: ThreadSafeQueue = ThreadSafeQueue<AssuranceEvent>(withLimit: 200)
    let inboundQueue: ThreadSafeQueue = ThreadSafeQueue<AssuranceEvent>(withLimit: 200)
    let inboundSource = DispatchSource.makeUserDataAddSource(queue: DispatchQueue.global(qos: .default))
    let outboundSource = DispatchSource.makeUserDataAddSource(queue: DispatchQueue.global(qos: .default))
    var canStartForwarding : Bool = false
    let pluginCollection : AssurancePluginCollection = AssurancePluginCollection()
    var statusUI : iOSStatusUI?
    var socket : SocketConnectable?
    
    /// Initializer with instance of  `Assurance` extension
    init(_ assuranceExtension: Assurance) {
        self.assuranceExtension = assuranceExtension
        handleInBoundEvents()
        handleOutBoundEvents()
    }

    /// Called when a valid assurance deeplink url is received from the startSession API
    /// Calling this method will attempt to display the pincode screen for session authentication
    ///
    /// Thread : Listener thread from EventHub
    func startSession() {
        let pinCodeScreen = iOSPinCodeScreen.init(withExtension: assuranceExtension)
        self.pinCodeScreen = pinCodeScreen
        self.socket = WebViewSocketConnection(withDelegate: self)
        self.statusUI = iOSStatusUI.init(withSession: self)

        // TODO revert before commit
                
        pinCodeScreen.getSocketURL(callback: { socketUrl in
            // Thread : main thread (this callback is called from `overrideUrlLoad` method of WKWebView)
            Log.debug(label: AssuranceConstants.LOG_TAG, "Attempting to make a socket connection with URL : \(socketUrl)")
            pinCodeScreen.connectionInitialized()
            self.socket?.connect(withUrl: socketUrl)
        })
        
//        socket = WebViewSocketConnection(withDelegate: self)
//        sleep(3)
//        self.socket?.connect(withUrl: URL(string: "wss://connect.griffon.adobe.com/client/v1?sessionId=7e672843-076d-4f2b-99c9-a55a29a77424&token=6996&orgId=972C898555E9F7BC7F000101@AdobeOrg&clientId=3BF1355F-6A56-4A87-B6F9-D3072BB18692")!)
    }
    
    func sendEvent(_ assuranceEvent : AssuranceEvent) {
        outboundQueue.enqueue(newElement: assuranceEvent)
        outboundSource.add(data: 1)
    }
    
    func sendClientInfoEvent() {
        Log.debug(label: AssuranceConstants.LOG_TAG, "Sending client info event to Assurance")
        let clientEvent = AssuranceEvent.init(type: AssuranceConstants.EventType.CLIENT, payload: AssuranceClientInfo.getData())
        self.socket?.sendEvent(clientEvent)
    }
    
    // MARK: - Private methods
    /// TODO
    private func handleOutBoundEvents() {
        outboundSource.setEventHandler(handler: {
            if (SocketState.OPEN != self.socket?.socketState) {
                Log.trace(label: AssuranceConstants.LOG_TAG, "Queuing event before connection has been initialized(waiting for deep link to initialize connection with pin code entry)")
                return
            }
            
            if (!self.canStartForwarding) {
                Log.trace(label: AssuranceConstants.LOG_TAG, "Assurance Extension hasn't received startForwarding control event to start sending the queued events.")
                return
            }
            
            while (self.outboundQueue.size() >= 0) {
                let event = self.outboundQueue.dequeue()
                if let event = event {
                    self.socket?.sendEvent(event)
                }
            }
        })
        outboundSource.resume()
    }
    
    /// TODO
    private func handleInBoundEvents() {
        inboundSource.setEventHandler(handler: {
            while (self.inboundQueue.size() >= 0) {
                let event = self.inboundQueue.dequeue()
                if let event = event {
                    self.pluginCollection.notifyPluginsOfEvent(event)
                }
            }
        })
        inboundSource.resume()
    }

}
