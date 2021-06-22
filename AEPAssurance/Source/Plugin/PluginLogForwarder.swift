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

/// Plugin that acts on command to forward logs
///
/// The plugin gets invoked with Assurance command event having
/// - vendor  : "com.adobe.griffon.mobile"
/// - command type   : "logForwarding"
///
/// This plugin gets registered with `PluginHub` during the registration of Assurance extension.
/// Note: The debug logs through AEPServices goes to STDERR
/// Once the command to forward logs is received, this plugin interrupts the logs by creating a Pipe and replacing the STDERR file descriptor to pipe's file descriptor.
/// Plugin then reads the input to the pipe and forwards the logs to the connected assurance session.
class PluginLogForwarder: AssurancePlugin {

    weak var session: AssuranceSession?
    var vendor: String = AssuranceConstants.Vendor.MOBILE
    var commandType: String = AssuranceConstants.CommandType.LOG_FORWARDING

    var currentlyRunning: Bool = false
    private var logPipe = Pipe() /// consumes the log messages from STDERR
    private var consoleRedirectPipe = Pipe() /// outputs the log message back to STDERR
    private var logQueue: DispatchQueue = DispatchQueue(label: "com.adobe.assurance.log.forwarder")

    lazy var savedStdError: Int32 = dup(fileno(stderr))

    init() {
        /// Set up a read handler which fires when data is written into `logPipe`
        /// This handler intercepts the log, sends to assurance session and then redirects back to the console.
        logPipe.fileHandleForReading.readabilityHandler = { [weak self] fileHandle in
            let data = fileHandle.availableData
            if let logLine = String(data: data, encoding: String.Encoding.utf8) {
                self?.session?.sendEvent(AssuranceEvent(type: AssuranceConstants.EventType.LOG, payload: ["logline": AnyCodable.init(logLine)]))
            }

            /// writes log back to stderr
            self?.consoleRedirectPipe.fileHandleForWriting.write(data)
        }
    }

    /// this protocol method is called from `PluginHub` to handle screenshot command
    func receiveEvent(_ event: AssuranceEvent) {
        // quick bail, if you cannot read the session instance
        guard let _ = self.session else {
            Log.debug(label: AssuranceConstants.LOG_TAG, "Unable to get the session instance. Assurance SDK is ignoring the command to start/stop forwarding logs.")
            return
        }

        guard let commandDetails = event.commandDetails else {
            Log.debug(label: AssuranceConstants.LOG_TAG, "PluginLogForwarder - Command details empty. Assurance SDK is ignoring the command to start/stop forwarding logs.")
            return
        }

        guard let forwardingEnabled = commandDetails["enable"] as? Bool else {
            Log.debug(label: AssuranceConstants.LOG_TAG, "PluginLogForwarder - Unable to read the enable key for log forwarding request. Ignoring the command to start/stop forwarding logs.")
            return
        }

        forwardingEnabled ? startForwarding() : stopForwarding()

    }

    /// protocol method is called from this Plugin is registered with `PluginHub`
    func onRegistered(_ session: AssuranceSession) {
        self.session = session
    }

    // no op - protocol methods
    func onSessionConnected() {}

    func onSessionDisconnectedWithCloseCode(_ closeCode: Int) {}

    func onSessionTerminated() {}

    func startForwarding() {
        logQueue.async {
            if self.currentlyRunning {
                Log.debug(label: AssuranceConstants.LOG_TAG, "Assurance SDK is already forwarding logs. Log forwarding start command is ignored.")
                return
            }

            self.currentlyRunning = true
            self.savedStdError = dup(fileno(stderr))

            /// manual page for dup2 : https://man7.org/linux/man-pages/man2/dup.2.html
            /// syntax : int dup2(int oldfd, int newfd);
            dup2(fileno(stderr), self.consoleRedirectPipe.fileHandleForWriting.fileDescriptor)
            dup2(self.logPipe.fileHandleForWriting.fileDescriptor, fileno(stderr))
        }
    }

    func stopForwarding() {
        logQueue.async {
            if !self.currentlyRunning {
                Log.debug(label: AssuranceConstants.LOG_TAG, "Assurance SDK is currently not forwarding logs. Log forwarding stop command is ignored.")
                return
            }

            dup2(self.savedStdError, fileno(stderr))
            close(self.savedStdError)
            self.currentlyRunning = false
        }
    }

}
