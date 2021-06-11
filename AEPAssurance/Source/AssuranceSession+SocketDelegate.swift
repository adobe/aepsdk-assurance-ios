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

extension AssuranceSession: SocketDelegate {
    func webSocketDidConnect(_ socket: SocketConnectable) {
        Log.debug(label: AssuranceConstants.LOG_TAG, "Assurance session successfully connected.")
        self.sendClientInfoEvent()
    }

    func webSocketDidDisconnect(_ socket: SocketConnectable, _ closeCode: Int, _ reason: String, _ wasClean: Bool) {
        // coming soon
    }

    func webSocketOnError(_ socket: SocketConnectable) {
        Log.debug(label: AssuranceConstants.LOG_TAG, "AssuranceSession: webSocketOnError is called. Error occurred during socket connection.")
    }

    /// Invoked when an `AssuranceEvent` is received from web socket connection
    func webSocket(_ socket: SocketConnectable, didReceiveEvent event: AssuranceEvent) {
        Log.trace(label: AssuranceConstants.LOG_TAG, "Received event from assurance session - \(event.description)")

        // add the incoming event to inboundQueue and process them
        inboundQueue.enqueue(newElement: event)
        inboundSource.add(data: 1)
    }

    /// Invoked when an socket connection state changes
    /// - Parameters:
    ///     - socket - the socket instance
    ///     - state - the present socket state
    func webSocket(_ socket: SocketConnectable, didChangeState state: SocketState) {
        Log.debug(label: AssuranceConstants.LOG_TAG, "AssuranceSession: Socket state changed \(socket.socketState)")
        switch state {
        case .CONNECTING:
            break
        case .OPEN:
            assuranceExtension.connectedWebSocketURL = socket.socketURL?.absoluteString
        case .CLOSING:
            break
        case .CLOSED:
            break
        case .UNKNOWN:
            break
        }
    }

}