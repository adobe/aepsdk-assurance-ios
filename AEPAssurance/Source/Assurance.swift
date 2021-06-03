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

import AEPCore
import AEPServices
import Foundation

public class Assurance: NSObject, Extension {

    public var name = AssuranceConstants.EXTENSION_NAME
    public var friendlyName = AssuranceConstants.FRIENDLY_NAME
    public static var extensionVersion = AssuranceConstants.EXTENSION_VERSION
    public var metadata: [String: String]?
    public var runtime: ExtensionRuntime

    let datastore = NamedCollectionDataStore(name: AssuranceConstants.EXTENSION_NAME)
    var assuranceSession: AssuranceSession?

    var sessionId: String? {
        get {
            datastore.getString(key: AssuranceConstants.DataStoreKeys.SESSION_ID)
        }
        set {
            datastore.set(key: AssuranceConstants.DataStoreKeys.SESSION_ID, value: newValue)
        }
    }

    private let DEFAULT_ENVIRONMENT = AssuranceEnvironment.prod
    var environment: AssuranceEnvironment {
        get {
            AssuranceEnvironment.init(envString: datastore.getString(key: AssuranceConstants.DataStoreKeys.ENVIRONMENT) ?? DEFAULT_ENVIRONMENT.rawValue)
        }
        set {
            datastore.set(key: AssuranceConstants.DataStoreKeys.ENVIRONMENT, value: newValue.rawValue)
        }
    }

    // getter for client ID
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

    public func onRegistered() {
        registerListener(type: EventType.wildcard, source: EventSource.wildcard, listener: handleWildcardEvent)
        self.assuranceSession = AssuranceSession(self)
    }

    public func onUnregistered() {}

    public required init?(runtime: ExtensionRuntime) {
        self.runtime = runtime
    }

    public func readyForEvent(_ event: Event) -> Bool {
        return true
    }

    // MARK: - Event handlers

    /// Called by the wildcard listener to handle all the events dispatched from MobileCore's event hub.
    /// Each mobile core event is converted to `AssuranceEvent` and is sent over the socket.
    /// - Parameters:
    /// - event - a mobileCore's `Event`
    private func handleWildcardEvent(event: Event) {
        if event.isSharedStateEvent {
            processSharedStateEvent(event: event)
            return
        }

        if event.isPlacesRequestEvent {
            handlePlacesRequest(event: event)
        } else if event.isPlacesResponseEvent {
            handlePlacesResponse(event: event)
        } else if event.isAssuranceRequestContent {
            handleAssuranceRequestContent(event: event)
        }

        // forward all the event to Assurance session
        let assuranceEvent = AssuranceEvent.from(event: event)
        assuranceSession?.sendEvent(assuranceEvent)
    }

    private func handleAssuranceRequestContent(event: Event) {
        guard let startSessionData = event.data else {
            Log.debug(label: AssuranceConstants.LOG_TAG, "Assurance start session event received with empty data. Dropping event.")
            return
        }

        guard let deeplinkUrlString = startSessionData[AssuranceConstants.EventDataKey.START_SESSION_URL] as? String else {
            Log.debug(label: AssuranceConstants.LOG_TAG, "Assurance start session event received with no deeplink url. Dropping event.")
            return
        }

        let deeplinkURL = URL(string: deeplinkUrlString)
        guard let sessionId = deeplinkURL?.params[AssuranceConstants.Deeplink.SESSIONID_KEY] else {
            Log.debug(label: AssuranceConstants.LOG_TAG, "Deeplink URL is invalid. Does not contain 'adb_validation_sessionid' query parameter : " + deeplinkUrlString)
            return
        }

        // make sure the sessionID is an UUID string
        guard let _ = UUID(uuidString: sessionId) else {
            Log.debug(label: AssuranceConstants.LOG_TAG, "Deeplink URL is invalid. It contains sessionId that is not an valid UUID : " + deeplinkUrlString)
            return
        }

        // Read the environment query parameter from the deeplink url
        let environmentString = deeplinkURL?.params[AssuranceConstants.Deeplink.ENVIRONMENT_KEY] ?? ""

        // save the environment and sessionID
        environment = AssuranceEnvironment.init(envString: environmentString)
        self.sessionId = sessionId
        assuranceSession?.startSession()
    }

    // MARK: Places event handlers

    /// Handle places request events and log them in the client statusUI.
    ///
    /// - Parameters:
    ///     - event - a mobileCore's places request event
    private func handlePlacesRequest(event: Event) {
        if event.isRequestNearByPOIEvent {
            assuranceSession?.addClientLog("Places - Requesting \(event.poiCount) nearby POIs from (\(event.latitude), \(event.longitude))", visibility: .normal)
        } else if event.isRequestResetEvent {
            assuranceSession?.addClientLog("Places - Resetting location", visibility: .normal)
        }
    }

    /// Handle places response events and log them in the client statusUI.
    ///
    /// - Parameters:
    ///     - event - a mobileCore's places response event
    private func handlePlacesResponse(event: Event) {
        if event.isResponseRegionEvent {
            assuranceSession?.addClientLog("Places - Processed \(event.regionEventType) for region \(event.regionName).", visibility: .normal)
        } else if event.isResponseNearByEvent {
            let nearByPOIs = event.nearByPOIs
            for poi in nearByPOIs {
                guard let poiDictionary = poi as? [String: Any] else {
                    return
                }
                assuranceSession?.addClientLog("\t  \(poiDictionary["regionname"] as? String ?? "Unknown")", visibility: .high)
            }
            assuranceSession?.addClientLog("Places - Found \(nearByPOIs.count) nearby POIs\(nearByPOIs.count > 0 ? " :" : ".")", visibility: .high)
        }
    }

    /// Method to process the sharedState events from the event hub.
    /// Shared State Change events are special events to Assurance.  On the arrival of which, Assurance extension attempts to
    /// extract the shared state details associated with the shared state change, and then append them to this event.
    /// Assurance extension handles both regular and XDM shared state change events.
    ///
    /// - Parameter event - a mobileCore's `Event`
    private func processSharedStateEvent(event: Event) {
        // early bail out if unable to find the stateOwner
        guard let stateOwner = event.sharedStateOwner else {
            Log.debug(label: AssuranceConstants.LOG_TAG, "Unable to find shared state owner for the shared state change event. Dropping event.")
            return
        }

        // Differentiate the type of shared state using the event name and get the state content accordingly
        // Event Name for XDM shared          = "Shared state content (XDM)"
        // Event Name for Regular  shared     = "Shared state content"
        var sharedStateResult: SharedStateResult?
        var sharedContentKey: String

        if AssuranceConstants.SDKEventName.XDM_SHARED_STATE_CHANGE.lowercased() == event.name.lowercased() {
            sharedContentKey = AssuranceConstants.PayloadKey.XDM_SHARED_STATE_DATA
            sharedStateResult = runtime.getXDMSharedState(extensionName: stateOwner, event: nil, barrier: false)
        } else {
            sharedContentKey = AssuranceConstants.PayloadKey.SHARED_STATE_DATA
            sharedStateResult = runtime.getSharedState(extensionName: stateOwner, event: nil, barrier: false)
        }

        // do not send any sharedState thats empty, this includes Assurance not logging any pending shared states
        guard let sharedState = sharedStateResult else {
            return
        }

        if sharedState.status != .set {
            return
        }

        let sharedStatePayload = [sharedContentKey: sharedState.value]
        var assuranceEvent = AssuranceEvent.from(event: event)
        assuranceEvent.payload?.updateValue(AnyCodable.init(sharedStatePayload), forKey: AssuranceConstants.PayloadKey.METADATA)
        assuranceSession?.sendEvent(assuranceEvent)
    }
}
