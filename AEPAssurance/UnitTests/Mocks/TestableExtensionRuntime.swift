//
// Copyright 2021 Adobe. All rights reserved.
// This file is licensed to you under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License. You may obtain a copy
// of the License at http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software distributed under
// the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR REPRESENTATIONS
// OF ANY KIND, either express or implied. See the License for the specific language
// governing permissions and limitations under the License.
//

@testable import AEPCore
import Foundation

class TestableExtensionRuntime: ExtensionRuntime {
    var listeners: [String: EventListener] = [:]
    var dispatchedEvents: [Event] = []
    var sharedStates: [[String: Any]?] = []
    public var createdXdmSharedStates: [[String: Any]?] = []
    var otherSharedStates: [String: SharedStateResult] = [:]
    var otherXDMSharedStates: [String: SharedStateResult] = [:]

    func getListener(type: String, source: String) -> EventListener? {
        listeners["\(type)-\(source)"]
    }

    func simulateComingEvent(event: Event) {
        listeners["\(event.type)-\(event.source)"]?(event)
        listeners["\(EventType.wildcard)-\(EventSource.wildcard)"]?(event)
    }

    func unregisterExtension() {
        // no-op
    }

    func registerListener(type: String, source: String, listener: @escaping EventListener) {
        listeners["\(type)-\(source)"] = listener
    }

    func dispatch(event: Event) {
        dispatchedEvents += [event]
    }

    func createSharedState(data: [String: Any], event _: Event?) {
        sharedStates += [data]
    }

    func createPendingSharedState(event _: Event?) -> SharedStateResolver {
        { data in
            self.sharedStates += [data]
        }
    }

    func getSharedState(extensionName: String, event: Event?, barrier _: Bool) -> SharedStateResult? {
        otherSharedStates["\(extensionName)-\(String(describing: event?.id))"] ?? nil
    }

    public func createXDMSharedState(data: [String: Any], event _: Event?) {
        createdXdmSharedStates += [data]
    }

    func createPendingXDMSharedState(event _: Event?) -> SharedStateResolver {
        { data in
            self.createdXdmSharedStates += [data]
        }
    }

    func getXDMSharedState(extensionName: String, event _: Event?, barrier _: Bool) -> SharedStateResult? {
        otherXDMSharedStates["\(extensionName)"] ?? nil
    }

    func simulateSharedState(extensionName: String, event: Event?, data: (value: [String: Any]?, status: SharedStateStatus)) {
        otherSharedStates["\(extensionName)-\(String(describing: event?.id))"] = SharedStateResult(status: data.status, value: data.value)
    }

    public func simulateXDMSharedState(for extensionName: String, data: (value: [String: Any]?, status: SharedStateStatus)) {
        otherXDMSharedStates["\(extensionName)"] = SharedStateResult(status: data.status, value: data.value)
    }

    /// clear the events and shared states that have been created by the current extension
    public func reset() {
        dispatchedEvents = []
        sharedStates = []
    }

    func startEvents() {}

    func stopEvents() {}
}

extension TestableExtensionRuntime {
    var firstEvent: Event? {
        dispatchedEvents[0]
    }

    var secondEvent: Event? {
        dispatchedEvents[1]
    }

    var thirdEvent: Event? {
        dispatchedEvents[2]
    }

    var firstSharedState: [String: Any]? {
        sharedStates[0]
    }

    var secondSharedState: [String: Any]? {
        sharedStates[1]
    }

    var thirdSharedState: [String: Any]? {
        sharedStates[2]
    }
}
