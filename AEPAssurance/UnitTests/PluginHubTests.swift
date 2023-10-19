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
import Foundation
import XCTest

class PluginHubTests: XCTestCase {

    let pluginHub = PluginHub()

    // sample plugins
    var pluginTaco = PluginTaco()   // vendor "Food"
    var pluginBlue = PluginBlue()   // vendor "Color"
    var pluginGreen = PluginGreen() // vendor "Color"
    var pluginColorWildCard = PluginColorWildCard() // vendor "Color"

    let runtime = TestableExtensionRuntime()
    var session: MockSession?
    var mockStateManager: MockStateManager?

    // MARK: - Setup

    override func setUp() {
        mockStateManager = MockStateManager(runtime)
        let mockSessionOrchestrator = MockSessionOrchestrator(stateManager: mockStateManager!)
        let sessionDetail = AssuranceSessionDetails(sessionId: "mocksessionId", clientId: "clientId", environment: .dev)
        session = MockSession(sessionDetails: sessionDetail, stateManager: mockStateManager!, sessionOrchestrator: mockSessionOrchestrator, outboundEvents: nil)

        pluginHub.registerPlugin(pluginBlue, toSession: session!)
        pluginHub.registerPlugin(pluginGreen, toSession: session!)
        pluginHub.registerPlugin(pluginTaco, toSession: session!)
        pluginHub.registerPlugin(pluginColorWildCard, toSession: session!)
    }

    // MARK: - Tests

    func test_registerPlugin() {
        // registration of plugin is done in the setup step

        // verify
        XCTAssertEqual(2, pluginHub.pluginCollection.count) // 2 Indicates the number of unique vendors
        XCTAssertEqual(3, pluginHub.pluginCollection["Color".hash]?.count) // pluginCollection for the same vendor are grouped by their hash
        XCTAssertEqual(1, pluginHub.pluginCollection["Food".hash]?.count) // 1 plugin for vendor "Food" - PluginTaco

        XCTAssertTrue(pluginBlue.isOnRegisterCalled)
        XCTAssertTrue(pluginGreen.isOnRegisterCalled)
        XCTAssertTrue(pluginTaco.isOnRegisterCalled)
    }

    func test_notifyPluginsOfEvent() {
        // test
        pluginHub.notifyPluginsOfEvent(tacoEvent)

        // verify
        XCTAssertFalse(pluginBlue.eventReceived)
        XCTAssertFalse(pluginGreen.eventReceived)
        XCTAssertTrue(pluginTaco.eventReceived)
        XCTAssertFalse(pluginColorWildCard.eventReceived)

        // test
        pluginHub.notifyPluginsOfEvent(blueEvent)

        // verify pluginBlue is notified about the event
        XCTAssertTrue(pluginBlue.eventReceived)
        XCTAssertTrue(pluginColorWildCard.eventReceived)
    }

    func test_notifyPluginsOfEvent_WildcardPlugin() {
        // test
        pluginHub.notifyPluginsOfEvent(blueEvent)

        // verify that the wildcard plugin is notified
        XCTAssertTrue(pluginColorWildCard.eventReceived)
    }

    func test_notifyPluginsOfEvent_randomType() {
        // test
        pluginHub.notifyPluginsOfEvent(randomTypeEvent)

        // verify that only wildcard plugin is invoked
        XCTAssertFalse(pluginBlue.eventReceived)
        XCTAssertFalse(pluginGreen.eventReceived)
        XCTAssertTrue(pluginColorWildCard.eventReceived)
    }

    func test_notifyPluginsOfEvent_randomVendor() {
        // test
        pluginHub.notifyPluginsOfEvent(randomVendorEvent)

        // verify that no plugins are invoked
        XCTAssertFalse(pluginBlue.eventReceived)
        XCTAssertFalse(pluginGreen.eventReceived)
        XCTAssertFalse(pluginColorWildCard.eventReceived)
    }

    func test_notifyPluginsOnConnect() {
        // test
        pluginHub.notifyPluginsOnConnect()

        // verify
        XCTAssertTrue(pluginBlue.isSessionConnectedCalled)
        XCTAssertTrue(pluginGreen.isSessionConnectedCalled)
        XCTAssertTrue(pluginTaco.isSessionConnectedCalled)
    }

    func test_notifyPluginsOnDisconnect() {
        // test
        pluginHub.notifyPluginsOnDisconnect(withCloseCode: 1000)

        // verify
        XCTAssertTrue(pluginBlue.isSessionDisconnectCalled)
        XCTAssertTrue(pluginGreen.isSessionDisconnectCalled)
        XCTAssertTrue(pluginTaco.isSessionDisconnectCalled)
    }

    func test_notifyPluginsOnSessionTerminated() {
        // test
        pluginHub.notifyPluginsOnSessionTerminated()

        // verify
        XCTAssertTrue(pluginBlue.isSessionTerminatedCalled)
        XCTAssertTrue(pluginGreen.isSessionTerminatedCalled)
        XCTAssertTrue(pluginTaco.isSessionTerminatedCalled)
    }

    // MARK: - Helper properties

    private var tacoEvent: AssuranceEvent {
        return AssuranceEvent(type: "control", payload: ["type": "Taco"], vendor: "Food")
    }

    private var blueEvent: AssuranceEvent {
        return AssuranceEvent(type: "control", payload: ["type": "Blue"], vendor: "Color")
    }

    private var randomTypeEvent: AssuranceEvent {
        return AssuranceEvent(type: "control", payload: ["type": "random"], vendor: "Color")
    }

    private var randomVendorEvent: AssuranceEvent {
        return AssuranceEvent(type: "control", payload: ["type": "Blue"], vendor: "random")
    }

}

// MARK: - Sample plugin classes

class PluginBlue: AssurancePlugin {
    var vendor: String = "Color"
    var commandType: String = "Blue"

    var isOnRegisterCalled = false
    func onRegistered(_ session: AssuranceSession) {
        isOnRegisterCalled = true
    }

    var eventReceived = false
    func receiveEvent(_ event: AssuranceEvent) {
        eventReceived = true
    }

    var isSessionConnectedCalled = false
    func onSessionConnected() {
        isSessionConnectedCalled = true
    }

    var isSessionDisconnectCalled = false
    func onSessionDisconnectedWithCloseCode(_ closeCode: Int) {
        isSessionDisconnectCalled = true
    }

    var isSessionTerminatedCalled = false
    func onSessionTerminated() {
        isSessionTerminatedCalled = true
    }
}

class PluginGreen: AssurancePlugin {

    var vendor: String = "Color"
    var commandType: String = "Green"

    var isOnRegisterCalled = false
    func onRegistered(_ session: AssuranceSession) {
        isOnRegisterCalled = true
    }

    var eventReceived = false
    func receiveEvent(_ event: AssuranceEvent) {
        eventReceived = true
    }

    var isSessionConnectedCalled = false
    func onSessionConnected() {
        isSessionConnectedCalled = true
    }

    var isSessionDisconnectCalled = false
    func onSessionDisconnectedWithCloseCode(_ closeCode: Int) {
        isSessionDisconnectCalled = true
    }

    var isSessionTerminatedCalled = false
    func onSessionTerminated() {
        isSessionTerminatedCalled = true
    }
}

// A wildcard plugin listens to all event directed towards the vendor "Color"
class PluginColorWildCard: AssurancePlugin {

    var vendor: String = "Color"
    var commandType: String = "wildcard"

    var isOnRegisterCalled = false
    func onRegistered(_ session: AssuranceSession) {
        isOnRegisterCalled = true
    }

    var eventReceived = false
    func receiveEvent(_ event: AssuranceEvent) {
        eventReceived = true
    }

    func onSessionConnected() {}

    func onSessionDisconnectedWithCloseCode(_ closeCode: Int) {}

    func onSessionTerminated() {}
}

class PluginTaco: AssurancePlugin {

    var expectation: XCTestExpectation?
    var vendor: String = "Food"
    var commandType: String = "Taco"

    var isOnRegisterCalled = false
    func onRegistered(_ session: AssuranceSession) {
        isOnRegisterCalled = true
    }

    var eventReceived = false
    var receivedEvent: AssuranceEvent? = nil
    func receiveEvent(_ event: AssuranceEvent) {
        expectation?.fulfill()
        eventReceived = true
        receivedEvent = event
    }

    var isSessionConnectedCalled = false
    func onSessionConnected() {
        expectation?.fulfill()
        isSessionConnectedCalled = true
    }

    var isSessionDisconnectCalled = false
    func onSessionDisconnectedWithCloseCode(_ closeCode: Int) {
        isSessionDisconnectCalled = true
    }

    var isSessionTerminatedCalled = false
    func onSessionTerminated() {
        isSessionTerminatedCalled = true
    }
}
