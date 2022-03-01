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

@objc(AEPMobileAssurance)
public class Assurance: NSObject, Extension {

    /// Time before assurance shuts down on non receipt of start session event.
    let shutdownTime: Int

    public var name = AssuranceConstants.EXTENSION_NAME
    public var friendlyName = AssuranceConstants.FRIENDLY_NAME
    public static var extensionVersion = AssuranceConstants.EXTENSION_VERSION
    public var metadata: [String: String]?
    public var runtime: ExtensionRuntime

    var assuranceSession: AssuranceSession?
    var timer: DispatchSourceTimer?
    let stateManager: AssuranceStateManager
    


    public func onRegistered() {
        registerListener(type: EventType.wildcard, source: EventSource.wildcard, listener: handleWildcardEvent)
        self.assuranceSession = AssuranceSession(stateManager)

        /// if the Assurance session was already connected in the previous app session, go ahead and reconnect socket
        /// and do not turn on the unregister timer
        if stateManager.connectedWebSocketURL != nil {
            stateManager.shareState()
            Log.trace(label: AssuranceConstants.LOG_TAG, "Assurance Session was already connected during previous app launch. Attempting to reconnect. URL : \(String(describing: stateManager.connectedWebSocketURL))")
            assuranceSession?.startSession()
            return
        }

        /// if the Assurance session is not previously connected, turn on 5 sec timer to wait for Assurance deeplink
        startShutDownTimer()
    }

    public func onUnregistered() {}

    public required init?(runtime: ExtensionRuntime) {
        self.runtime = runtime
        self.shutdownTime = AssuranceConstants.SHUTDOWN_TIME
        self.stateManager = AssuranceStateManager(runtime)
    }

    /// Initializer for testing purposes to mock the shut down time .
    init?(runtime: ExtensionRuntime, shutdownTime: Int, stateManager: AssuranceStateManager) {
        self.runtime = runtime
        self.shutdownTime = shutdownTime
        self.stateManager = stateManager
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
        if event.isAssuranceRequestContent {
            handleAssuranceRequestContent(event: event)
        }

        guard let session = assuranceSession, session.canProcessSDKEvents else {
            return
        }

        if event.isSharedStateEvent {
            processSharedStateEvent(event: event)
            return
        }

        // forward all events to Assurance session
        let assuranceEvent = AssuranceEvent.from(event: event)
        session.sendEvent(assuranceEvent)

        if event.isPlacesRequestEvent {
            handlePlacesRequest(event: event)
        } else if event.isPlacesResponseEvent {
            handlePlacesResponse(event: event)
        }
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

        // invalidate the timer
        invalidateTimer()

        // save the environment and sessionID
        stateManager.environment = AssuranceEnvironment.init(envString: environmentString)
        stateManager.sessionId = sessionId
        stateManager.shareState()

        Log.trace(label: AssuranceConstants.LOG_TAG, "Received sessionID, Initializing Assurance session. \(sessionId)")
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
            assuranceSession?.addClientLog("Places - Found \(nearByPOIs.count) nearby POIs\(!nearByPOIs.isEmpty ? " :" : ".")", visibility: .high)
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

    // MARK: Shutdown timer methods

    /// Start the shutdown timer in the background queue without blocking the current thread.
    /// If the timer get fired, then it shuts down the assurance extension.
    private func startShutDownTimer() {
        Log.debug(label: AssuranceConstants.LOG_TAG, "Assurance shutdown timer started. Waiting for 5 seconds to receive assurance session url.")
        let queue = DispatchQueue.init(label: "com.adobe.assurance.shutdowntimer", qos: .background)
        timer = createDispatchTimer(queue: queue, block: {
            self.shutDownAssurance()
        })
    }

    /// Shuts down the assurance extension by setting the `shouldProcessEvents` to false. On which no more events
    /// are listened by assurance extension
    /// @see readyForEvent
    private func shutDownAssurance() {
        Log.debug(label: AssuranceConstants.LOG_TAG, "Timeout - Assurance extension did not receive session url. Shutting down from processing any further events.")
        invalidateTimer()
        Log.debug(label: AssuranceConstants.LOG_TAG, "Clearing the queued events and purging Assurance shared state.")
        self.assuranceSession?.shutDownSession()
        stateManager.clearState()
    }

    /// Invalidate the ongoing timer and cleans it from memory
    private func invalidateTimer() {
        timer?.cancel()
        timer = nil
    }

    /// Creates and returns a new dispatch source object for timer events.
    /// The timer is set to fire in 5 seconds on the provided block.
    /// - Parameters:
    ///     - queue: the dispatch queue on which the timer runs
    ///     - block: the block that needs be executed once the timer fires
    /// - Returns: a configured `DispatchSourceTimer` instance
    private func createDispatchTimer(queue: DispatchQueue, block : @escaping () -> Void) -> DispatchSourceTimer {
        let timer = DispatchSource.makeTimerSource(queue: queue)
        timer.schedule(wallDeadline: .now() + DispatchTimeInterval.seconds(shutdownTime))
        timer.setEventHandler(handler: block)
        timer.resume()
        return timer
    }

  
}
