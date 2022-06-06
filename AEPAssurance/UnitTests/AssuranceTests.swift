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

@testable import AEPAssurance
@testable import AEPCore
@testable import AEPServices
import Foundation
import XCTest

class AssuranceTests: XCTestCase {

    let runtime = TestableExtensionRuntime()
    let mockUIService = MockUIService()
    let mockDataStore = MockDataStore()
    let mockMessagePresentable = MockFullscreenMessagePresentable()
    var mockSession: MockSession!
    var mockPresentation: MockPresentation!
    var stateManager: AssuranceStateManager!
    var assurance: Assurance!
    var mockSessionOrchestrator: MockSessionOrchestrator!

    override func setUp() {
        ServiceProvider.shared.uiService = mockUIService
        ServiceProvider.shared.namedKeyValueService = mockDataStore
        mockUIService.fullscreenMessage = mockMessagePresentable
        stateManager = AssuranceStateManager(runtime)
        mockSessionOrchestrator = MockSessionOrchestrator(stateManager: stateManager)
        mockPresentation = MockPresentation(sessionOrchestrator: mockSessionOrchestrator)

        assurance = Assurance(runtime: runtime)
        assurance.stateManager = stateManager
        assurance.sessionOrchestrator = mockSessionOrchestrator
        assurance.onRegistered()

        // mock the interaction with AssuranceSession class
        let mockSessionDetails = AssuranceSessionDetails(sessionId: "mockSessionId", clientId: "mockClientId")
        mockSession = MockSession(sessionDetails: mockSessionDetails, stateManager: stateManager, sessionOrchestrator: mockSessionOrchestrator, outboundEvents: nil)
        mockSession.presentation = mockPresentation
    }

    override func tearDown() {
        runtime.reset()
    }

    /*--------------------------------------------------
     startSession
     --------------------------------------------------*/
    func test_startSession() throws {
        // setup
        let eventData = [AssuranceConstants.EventDataKey.START_SESSION_URL: "griffon://?adb_validation_sessionid=28f4a622-d34f-4036-c81a-d21352144b57&env=stage"]
        let event = Event(name: "Test Request Identifiers",
                          type: AssuranceConstants.SDKEventType.ASSURANCE,
                          source: EventSource.requestContent,
                          data: eventData)

        // test
        runtime.simulateComingEvent(event: event)

        // verify
        wait(for: [mockSessionOrchestrator.createSessionCalled], timeout: 1.0)

        // verify that sessionID and environment are properly passed as session details
        XCTAssertEqual("28f4a622-d34f-4036-c81a-d21352144b57", mockSessionOrchestrator.createSessionDetails?.sessionId)
        XCTAssertEqual(.stage, mockSessionOrchestrator.createSessionDetails?.environment)
    
    }

    func test_startSession_withNonUUIDSessionID() throws {
        // setup
        let eventData = [AssuranceConstants.EventDataKey.START_SESSION_URL: "griffon://?adb_validation_sessionid=nonUUID&env=stage"]
        let event = Event(name: "Test Request Identifiers",
                          type: AssuranceConstants.SDKEventType.ASSURANCE,
                          source: EventSource.requestContent,
                          data: eventData)

        // test
        runtime.simulateComingEvent(event: event)

        // verify
        verify_PinCodeScreen_isNotShown()
        verify_sessionIdAndEnvironmentId_notSetInDatastore()
    }

    func test_startSession_withInvalidDeeplink() throws {
        // setup
        let eventData = [AssuranceConstants.EventDataKey.START_SESSION_URL: ""]
        let event = Event(name: "Test Request Identifiers",
                          type: AssuranceConstants.SDKEventType.ASSURANCE,
                          source: EventSource.requestContent,
                          data: eventData)

        // test
        runtime.simulateComingEvent(event: event)

        // verify
        verify_PinCodeScreen_isNotShown()
        verify_sessionIdAndEnvironmentId_notSetInDatastore()
    }

    func test_startSession_whenDeepLinkNotAString() throws {
        // setup
        let eventData = [AssuranceConstants.EventDataKey.START_SESSION_URL: 235663]
        let event = Event(name: "Test Request Identifiers",
                          type: AssuranceConstants.SDKEventType.ASSURANCE,
                          source: EventSource.requestContent,
                          data: eventData)

        // test
        runtime.simulateComingEvent(event: event)

        // verify
        verify_PinCodeScreen_isNotShown()
        verify_sessionIdAndEnvironmentId_notSetInDatastore()
    }

    func test_startSession_withNilEventData() throws {
        // setup
        let event = Event(name: "Test Request Identifiers",
                          type: AssuranceConstants.SDKEventType.ASSURANCE,
                          source: EventSource.requestContent,
                          data: nil)

        // test
        runtime.simulateComingEvent(event: event)

        // verify
        verify_PinCodeScreen_isNotShown()
        verify_sessionIdAndEnvironmentId_notSetInDatastore()
    }

    //--------------------------------------------------*/
    // MARK: - handleWildCardEvent
    //--------------------------------------------------*/

    func test_handleWildCardEvent_withNilEventData() throws {
        // setup
        mockSessionOrchestrator.session = mockSession
        mockSessionOrchestrator.canProcessSDKEventsReturnValue = true
        let event = Event(name: "Any SDK Event",
                          type: EventType.analytics,
                          source: EventSource.requestContent,
                          data: nil)

        // test
        runtime.simulateComingEvent(event: event)

        // verify that the event is sent to the session
        wait(for: [mockSessionOrchestrator.sendEventCalled], timeout: 1.0)
        XCTAssertEqual("Any SDK Event", mockSessionOrchestrator.sentEvent?.payload?[AssuranceConstants.ACPExtensionEventKey.NAME]?.stringValue)
    }

    func test_handleWildCardEvent_whenAssuranceShutDown() throws {
        // setup
        let event = Event(name: "Any SDK Event",
                          type: EventType.analytics,
                          source: EventSource.requestContent,
                          data: nil)
        mockSessionOrchestrator.sendEventCalled.isInverted = true
        
        mockSessionOrchestrator.canProcessSDKEventsReturnValue = false

        // test
        runtime.simulateComingEvent(event: event)

        // verify that the event is not forwarded to session
        wait(for: [mockSessionOrchestrator.sendEventCalled], timeout: 1.0)
    }

    //--------------------------------------------------*/
    // MARK: - handleSharedStateEvent
    //--------------------------------------------------*/

    func test_handleSharedStateEvent_Regular() throws {
        // setup
        mockSessionOrchestrator.session = mockSession
        mockSessionOrchestrator.canProcessSDKEventsReturnValue = true
        let sampleConfiguration = ["configkey": "value"]
        let configStateChangeEvent = Event(name: AssuranceConstants.SDKEventName.SHARED_STATE_CHANGE,
                                           type: EventType.hub,
                                           source: EventSource.sharedState,
                                           data: [AssuranceConstants.EventDataKey.SHARED_STATE_OWNER: AssuranceConstants.SharedStateName.CONFIGURATION])
        runtime.simulateSharedState(extensionName: AssuranceConstants.SharedStateName.CONFIGURATION, event: nil, data: (value: sampleConfiguration, status: .set))

        // test
        runtime.simulateComingEvent(event: configStateChangeEvent)

        // verify that the event is sent to the session
        wait(for: [mockSessionOrchestrator.sendEventCalled], timeout: 1.0)
        let metadata = mockSessionOrchestrator.sentEvent?.payload?[AssuranceConstants.PayloadKey.METADATA]?.dictionaryValue
        XCTAssertEqual(sampleConfiguration, metadata?["state.data"] as! Dictionary)
    }

    func test_handleSharedStateEvent_XDM() throws {
        // setup
        mockSessionOrchestrator.session = mockSession
        mockSessionOrchestrator.canProcessSDKEventsReturnValue = true
        let sampleConsent = ["consent": "yes"]
        let consentStateChangeEvent = Event(name: AssuranceConstants.SDKEventName.XDM_SHARED_STATE_CHANGE,
                                            type: EventType.hub,
                                            source: EventSource.sharedState,
                                            data: [AssuranceConstants.EventDataKey.SHARED_STATE_OWNER: "consentExtension"])
        runtime.simulateXDMSharedState(for: "consentExtension", data: (value: sampleConsent, status: .set))

        // test
        runtime.simulateComingEvent(event: consentStateChangeEvent)

        // verify that the event is sent to the session
        wait(for: [mockSessionOrchestrator.sendEventCalled], timeout: 1.0)
        let metadata = mockSessionOrchestrator.sentEvent?.payload?[AssuranceConstants.PayloadKey.METADATA]?.dictionaryValue
        XCTAssertEqual(sampleConsent, try XCTUnwrap(metadata?["xdm.state.data"]) as! Dictionary)
    }

    func test_handleSharedStateEvent_WhenSharedStatePending() throws {
        // setup
        let configStateChangeEvent = Event(name: AssuranceConstants.SDKEventName.SHARED_STATE_CHANGE,
                                           type: EventType.hub,
                                           source: EventSource.sharedState,
                                           data: [AssuranceConstants.EventDataKey.SHARED_STATE_OWNER: AssuranceConstants.SharedStateName.CONFIGURATION])
        runtime.simulateSharedState(extensionName: AssuranceConstants.SharedStateName.CONFIGURATION, event: nil, data: (value: nil, status: .pending))
        mockSessionOrchestrator.sendEventCalled.isInverted = true

        // test
        runtime.simulateComingEvent(event: configStateChangeEvent)

        // verify that the pending shared state are not sent
        wait(for: [mockSessionOrchestrator.sendEventCalled], timeout: 1.0)
    }

    func test_handleSharedStateEvent_WhenSharedStateNotAvailable() throws {
        // setup
        let configStateChangeEvent = Event(name: AssuranceConstants.SDKEventName.SHARED_STATE_CHANGE,
                                           type: EventType.hub,
                                           source: EventSource.sharedState,
                                           data: [AssuranceConstants.EventDataKey.SHARED_STATE_OWNER: AssuranceConstants.SharedStateName.CONFIGURATION])
        mockSessionOrchestrator.sendEventCalled.isInverted = true

        // test
        runtime.simulateComingEvent(event: configStateChangeEvent)

        // verify that the pending shared state are not sent
        wait(for: [mockSessionOrchestrator.sendEventCalled], timeout: 1.0)
    }

    func test_handleSharedStateEvent_WhenStateOwnerNil() throws {
        // setup
        let configStateChangeEvent = Event(name: AssuranceConstants.SDKEventName.SHARED_STATE_CHANGE,
                                           type: EventType.hub,
                                           source: EventSource.sharedState,
                                           data: [:]) // no stateOwner in data
        mockSessionOrchestrator.sendEventCalled.isInverted = true

        // test
        runtime.simulateComingEvent(event: configStateChangeEvent)

        // verify that the pending shared state are not sent
        wait(for: [mockSessionOrchestrator.sendEventCalled], timeout: 1.0)
    }

    func test_handlePlacesRequest_GetNearByPlaces() throws {
        // setup
        mockSessionOrchestrator.canProcessSDKEventsReturnValue = true
        mockSessionOrchestrator.session = mockSession
        
        // test
        runtime.simulateComingEvent(event: getNearbyPlacesRequestEvent)

        // verify that the client log is displayed
        wait(for: [mockPresentation.addClientLogCalled], timeout: 1.0)
        XCTAssertEqual(1, mockPresentation.addClientLogCalledTimes)
        XCTAssertEqual("Places - Requesting 7 nearby POIs from (12.340000, 23.455489)", mockPresentation.addClientLogMessage)
    }

    func test_handlePlacesRequest_PlacesReset() throws {
        // setup
        mockSessionOrchestrator.canProcessSDKEventsReturnValue = true
        mockSessionOrchestrator.session = mockSession
        
        // test
        runtime.simulateComingEvent(event: placesResetEvent)

        // verify that the client log is displayed
        wait(for: [mockPresentation.addClientLogCalled], timeout: 1.0)
        XCTAssertEqual(1, mockPresentation.addClientLogCalledTimes)
        XCTAssertEqual("Places - Resetting location", mockPresentation.addClientLogMessage)
    }

    func test_handlePlacesResponse_RegionEvent() throws {
        // setup
        mockSessionOrchestrator.canProcessSDKEventsReturnValue = true
        mockSessionOrchestrator.session = mockSession
        
        // test
        runtime.simulateComingEvent(event: regionEvent)

        // verify that the client log is displayed
        wait(for: [mockPresentation.addClientLogCalled], timeout: 1.0)
        XCTAssertEqual(1, mockPresentation.addClientLogCalledTimes)
        XCTAssertEqual("Places - Processed entry for region Green house.", mockPresentation.addClientLogMessage)
    }

    func test_handlePlacesResponse_nearbyPOIResponse() throws {
        // setup
        mockSessionOrchestrator.canProcessSDKEventsReturnValue = true
        mockSessionOrchestrator.session = mockSession
        
        // test
        runtime.simulateComingEvent(event: nearbyPOIResponse)

        // verify that the client log is displayed
        wait(for: [mockPresentation.addClientLogCalled], timeout: 1.0)
        XCTAssertEqual(3, mockPresentation.addClientLogCalledTimes)
    }

    func test_handlePlacesResponse_nearbyPOIResponseNoPOI() throws {
        // setup
        mockSessionOrchestrator.canProcessSDKEventsReturnValue = true
        mockSessionOrchestrator.session = mockSession
        
        // test
        runtime.simulateComingEvent(event: nearbyPOIResponseNoPOI)

        // verify that the client log is displayed
        wait(for: [mockPresentation.addClientLogCalled], timeout: 1.0)
        XCTAssertEqual(1, mockPresentation.addClientLogCalledTimes)
        XCTAssertEqual("Places - Found 0 nearby POIs.", mockPresentation.addClientLogMessage)
    }

    func test_readyForEvent() {
        // should always return true
        XCTAssertTrue(assurance.readyForEvent(regionEvent))
    }

    func test_onUnregistered() {
        XCTAssertNoThrow(assurance.onUnregistered())
    }

    // MARK: Private methods
    private func verify_PinCodeScreen_isNotShown() {
        XCTAssertFalse(mockUIService.createFullscreenMessageCalled)
        XCTAssertFalse(mockMessagePresentable.showCalled)
    }

    private func verify_sessionIdAndEnvironmentId_notSetInDatastore() {
        // verify that sessionID and environment are set in datastore
        XCTAssertNil(mockDataStore.dict[AssuranceConstants.DataStoreKeys.SESSION_ID] ?? nil)
        XCTAssertNil(mockDataStore.dict[AssuranceConstants.DataStoreKeys.ENVIRONMENT] ?? nil)
    }

    var getNearbyPlacesRequestEvent: Event {
        return Event(name: AssuranceConstants.Places.EventName.REQUEST_NEARBY_POI,
                     type: EventType.places,
                     source: EventSource.requestContent,
                     data: [
                        AssuranceConstants.Places.EventDataKeys.LATITUDE: 12.34,
                        AssuranceConstants.Places.EventDataKeys.LONGITUDE: 23.4554888443,
                        AssuranceConstants.Places.EventDataKeys.COUNT: 7
                     ])
    }

    var placesResetEvent: Event {
        return Event(name: AssuranceConstants.Places.EventName.REQUEST_RESET,
                     type: EventType.places,
                     source: EventSource.requestContent,
                     data: [:])
    }

    var regionEvent: Event {
        return Event(name: AssuranceConstants.Places.EventName.RESPONSE_REGION_EVENT,
                     type: EventType.places,
                     source: EventSource.responseContent,
                     data: [
                        AssuranceConstants.Places.EventDataKeys.REGION_EVENT_TYPE: "entry",
                        AssuranceConstants.Places.EventDataKeys.TRIGGERING_REGION: [AssuranceConstants.Places.EventDataKeys.REGION_NAME: "Green house"]
                     ])
    }

    var nearbyPOIResponse: Event {
        return Event(name: AssuranceConstants.Places.EventName.RESPONSE_NEARBY_POI_EVENT,
                     type: EventType.places,
                     source: EventSource.responseContent,
                     data: [
                        AssuranceConstants.Places.EventDataKeys.NEARBY_POI: [["regionName": "Golden Gate"],
                                                                             ["regionName": "Bay bridge"]]
                     ])
    }

    var nearbyPOIResponseNoPOI: Event {
        return Event(name: AssuranceConstants.Places.EventName.RESPONSE_NEARBY_POI_EVENT,
                     type: EventType.places,
                     source: EventSource.responseContent,
                     data: [
                        AssuranceConstants.Places.EventDataKeys.NEARBY_POI: []
                     ])
    }

}

extension Array where Element == AssuranceEvent {
    func hasEventWithName(_ stateName: String) -> Bool {
        for eachElement in self {
            if stateName == eachElement.payload![AssuranceConstants.ACPExtensionEventKey.NAME]?.stringValue {
                return true
            }
        }
        return false
    }
}
