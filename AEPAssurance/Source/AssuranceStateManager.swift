/*
 Copyright 2022 Adobe. All rights reserved.
 This file is licensed to you under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License. You may obtain a copy
 of the License at http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing, software distributed under
 the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR REPRESENTATIONS
 OF ANY KIND, either express or implied. See the License for the specific language
 governing permissions and limitations under the License.
 */

import AEPCore
import AEPServices
import Foundation
import UIKit

class AssuranceStateManager {

    let datastore = NamedCollectionDataStore(name: AssuranceConstants.EXTENSION_NAME)

    /// sessionID represents a unique identifier of a Project Griffon session to which this library attempts to connect.
    /// This property gets set when a deep-link initiating an assurance session is received.
    /// The presence of valid sessionID variable in `AssuranceStateManager` denotes a connection to Assurance session has been initiated.
    /// Note: The presence of sessionID does not denote active socket connection
    /// The absence of sessionID denotes a session connection is terminated or cancelled.
    var sessionId: String? {
        get {
            datastore.getString(key: AssuranceConstants.DataStoreKeys.SESSION_ID)
        }
        set {
            datastore.set(key: AssuranceConstants.DataStoreKeys.SESSION_ID, value: newValue)
        }
    }

    private let DEFAULT_ENVIRONMENT = AssuranceEnvironment.prod

    /// environment property defines the current environment to which the assurance session is connecting.
    /// This value should not be confused with launch environment.
    /// This value denotes the environment of Griffon services and UI running to which connection is made.
    /// This value is obtained from as a query parameter of deeplink URL.
    var environment: AssuranceEnvironment {
        get {
            AssuranceEnvironment.init(envString: datastore.getString(key: AssuranceConstants.DataStoreKeys.ENVIRONMENT) ?? DEFAULT_ENVIRONMENT.rawValue)
        }
        set {
            datastore.set(key: AssuranceConstants.DataStoreKeys.ENVIRONMENT, value: newValue.rawValue)
        }
    }

    /// clientID is an identifier to uniquely identify the connected device to an Assurance Session.
    /// This is a string representation of a UUID. This ID is required for client → server communications.
    /// A clientID is generated at the client and is persisted throughout the lifecycle of the app.
    lazy var clientID: String = {
        // return with clientId, if it is already available in persistence
        if let persistedClientID = datastore.getString(key: AssuranceConstants.DataStoreKeys.CLIENT_ID) {
            return persistedClientID
        }

        // If not generate a new clientId
        let newClientID = UUID().uuidString
        datastore.set(key: AssuranceConstants.DataStoreKeys.CLIENT_ID, value: newClientID)
        return newClientID

    }()

    /// property representing the webSocket URL of the ongoing Assurance session
    /// A valid value on this property represents that an assurance session is currently running.
    /// A nil value on this property represents there is no ongoing assurance session.
    var connectedWebSocketURL: String? {
        get {
            datastore.getString(key: AssuranceConstants.DataStoreKeys.SOCKETURL)
        }
        set {
            if let newValue = newValue {
                datastore.set(key: AssuranceConstants.DataStoreKeys.SOCKETURL, value: newValue)
            } else {
                datastore.remove(key: AssuranceConstants.DataStoreKeys.SOCKETURL)
            }
        }
    }

    let runtime: ExtensionRuntime
    init(_ runtime: ExtensionRuntime) {
        self.runtime = runtime
    }

    /// Call this function to create a new shared state for Assurance
    /// Important - An empty shared state is created if sessionId is not available
    func shareAssuranceState() {
        runtime.createSharedState(data: getSharedStateData() ?? [:], event: nil)
    }

    /// Call this function to empty the latest Assurance shared state
    func clearAssuranceState() {
        runtime.createSharedState(data: [:], event: nil)
    }

    /// Returns an Array of `AssuranceEvent`s containing regular and XDM shared state details of all the registered extensions.
    /// - Returns: an array of `AssuranceEvent`
    func getAllExtensionStateData() -> [AssuranceEvent] {
        var stateEvents: [AssuranceEvent] = []

        let eventHubState = runtime.getSharedState(extensionName: AssuranceConstants.SharedStateName.EVENT_HUB, event: nil, barrier: false)
        guard eventHubState?.status == .set, let registeredExtension = eventHubState?.value else {
            return stateEvents
        }

        guard let extensionsMap = registeredExtension[AssuranceConstants.EventDataKey.EXTENSIONS] as? [String: Any] else {
            return stateEvents
        }

        // add the eventHub shared state data to the list of shared state events
        stateEvents.append(prepareSharedStateEvent(owner: AssuranceConstants.SharedStateName.EVENT_HUB, eventName: "EventHub State", stateContent: registeredExtension, stateType: AssuranceConstants.PayloadKey.SHARED_STATE_DATA))

        for (extensionName, _) in extensionsMap {
            let friendlyName = getFriendlyExtensionName(extensionMap: extensionsMap, extensionName: extensionName)
            stateEvents.append(contentsOf: getStateForExtension(stateOwner: extensionName, friendlyName: friendlyName))
        }

        return stateEvents
    }

    /// Getter to retrieve the url encoded experience cloud orgId  from configuration
    /// Returns nil
    ///  - if core is not configured and configuration shared state is not available.
    ///  - if configuration shared state does not have value for `experienceCloud.org`
    ///
    /// - Returns: optional string representing the url coded experienceCloud Org Id to which the `MobileCore` is configured
    func getURLEncodedOrgID() -> String? {
        let configState = runtime.getSharedState(extensionName: AssuranceConstants.SharedStateName.CONFIGURATION, event: nil, barrier: false)
        let orgID = configState?.value?[AssuranceConstants.EventDataKey.CONFIG_ORG_ID] as? String
        return orgID?.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
    }

    // MARK: Helper methods to prepare shared state status events

    ///
    /// Gets the friendly name for an extension from EventHub's shared state.
    /// - Parameters:
    ///     - extensionMap: an eventHub's shared state dictionary containing details of the registered extension
    ///     - extensionName: the extension's name for which the friendly name has to be retrieved
    /// - Returns:A `String` representing the friendly name of the extension.
    private func getFriendlyExtensionName(extensionMap: [String: Any], extensionName: String) -> String {
        if let extensionDetails = extensionMap[extensionName] as? [String: Any] {
            if let friendlyName = extensionDetails[AssuranceConstants.EventDataKey.FRIENDLY_NAME] as? String {
                return friendlyName
            }
        }
        return extensionName
    }

    ///
    /// Fetches the Regular and XDM shared state data for the provided extension and prepares an  `Array` of  `AssuranceEvents`
    /// - Parameters:
    ///     - stateOwner: the state owner for which the shared state has to be fetched
    ///     - friendlyName: the friendly name for the extension
    /// - Returns: An array of Assurance Events containing shared state details.
    ///
    private func getStateForExtension(stateOwner: String, friendlyName: String) -> [AssuranceEvent] {
        var stateEvents: [AssuranceEvent] = []

        let regularSharedState = runtime.getSharedState(extensionName: stateOwner, event: nil, barrier: false)
        if regularSharedState?.status == .set, let stateValue = regularSharedState?.value {
            stateEvents.append(prepareSharedStateEvent(owner: stateOwner, eventName: "\(friendlyName) State", stateContent: stateValue, stateType: AssuranceConstants.PayloadKey.SHARED_STATE_DATA))
        }

        let xdmSharedState = runtime.getXDMSharedState(extensionName: stateOwner, event: nil, barrier: false)
        if xdmSharedState?.status == .set, let xdmStateValue = xdmSharedState?.value {
            stateEvents.append(prepareSharedStateEvent(owner: stateOwner, eventName: "\(friendlyName) XDM State", stateContent: xdmStateValue, stateType: AssuranceConstants.PayloadKey.XDM_SHARED_STATE_DATA))
        }

        return stateEvents
    }

    ///
    /// Prepares the shared state assurance event with  given details.
    /// - Parameters:
    ///     - owner: the shared state owner
    ///     - eventName : the event name for Assurance shared state event
    ///     - stateContent: the shared state contents
    ///     - stateType: type of shared state. Regular or XDM
    /// - Returns: An `AssuranceEvent` containing shared state data.
    ///
    private func prepareSharedStateEvent(owner: String, eventName: String, stateContent: [String: Any], stateType: String) -> AssuranceEvent {
        var payload: [String: AnyCodable] = [:]
        payload[AssuranceConstants.ACPExtensionEventKey.NAME] = AnyCodable.init(eventName)
        payload[AssuranceConstants.ACPExtensionEventKey.TYPE] = AnyCodable.init(EventType.hub.lowercased())
        payload[AssuranceConstants.ACPExtensionEventKey.SOURCE] = AnyCodable.init(EventSource.sharedState.lowercased())
        payload[AssuranceConstants.ACPExtensionEventKey.DATA] = [AssuranceConstants.EventDataKey.SHARED_STATE_OWNER: owner]
        payload[AssuranceConstants.PayloadKey.METADATA] = [stateType: stateContent]
        return AssuranceEvent(type: AssuranceConstants.EventType.GENERIC, payload: payload)
    }

    /// Prepares the shared state data for the Assurance Extension
    /// A valid shared state contains:
    /// - sessionid
    /// - clientid
    /// - integrationid
    ///
    /// - Returns: a dictionary  representing the current shared state data
    private func getSharedStateData() -> [String: String]? {
        // do not share shared state if the sessionId is unavailable
        guard let sessionId = sessionId else {
            return nil
        }

        var shareStateData: [String: String] = [:]
        shareStateData[AssuranceConstants.SharedStateKeys.CLIENT_ID] = clientID
        shareStateData[AssuranceConstants.SharedStateKeys.SESSION_ID] = sessionId
        shareStateData[AssuranceConstants.SharedStateKeys.INTEGRATION_ID] = sessionId + "|" + clientID
        return shareStateData
    }

}
