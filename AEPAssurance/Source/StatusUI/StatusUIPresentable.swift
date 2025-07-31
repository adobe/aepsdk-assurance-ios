//
// Copyright 2024 Adobe. All rights reserved.
// This file is licensed to you under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License. You may obtain a copy
// of the License at http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software distributed under
// the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR REPRESENTATIONS
// OF ANY KIND, either express or implied. See the License for the specific language
// governing permissions and limitations under the License.
//

import Foundation

/// Protocol defining the requirements for presenting status UI in Assurance sessions.
protocol StatusUIPresentable: AnyObject {
    /// Indicates whether the status UI is currently displayed.
    var displayed: Bool { get }

    /// Displays the status UI.
    func display()

    /// Updates the UI for an inactive socket (e.g., during reconnecting).
    func updateForSocketInActive()

    /// Updates the UI when the socket is connected.
    func updateForSocketConnected()

    /// Removes the status UI from the view.
    func remove()

    /// Adds a client log message to the UI.
    /// - Parameters:
    ///   - message: The log message string.
    ///   - visibility: The visibility level of the log message.
    func addClientLog(_ message: String, visibility: AssuranceClientLogVisibility)
}
