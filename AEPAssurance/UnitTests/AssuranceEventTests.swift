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
import AEPCore
import AEPServices
import XCTest

class AssuranceEventTests: XCTestCase {

    private let SAMPLE_PAYLOAD: [String: AnyCodable] = ["payloadkey": "value"]
    private let SAMPLE_METADATA: [String: AnyCodable] = ["metadatakey": "value"]
    private let SAMPLE_TIMESTAMP: Date = Date()

    /*--------------------------------------------------
     Initializer
     --------------------------------------------------*/
    func test_init() {
        // test
        let event = AssuranceEvent(type: "generic", payload: SAMPLE_PAYLOAD)

        // verify
        XCTAssertNotNil(event.eventID, "A random eventID should be generated")
        XCTAssertEqual("generic", event.type, "Inaccurate event type")
        XCTAssertEqual(SAMPLE_PAYLOAD, event.payload, "Inaccurate event payload")
        XCTAssertEqual(AssuranceConstants.Vendor.MOBILE, event.vendor, "vendor should default to Mobile")
    }

    func test_init_withTimestamp() {
        // test
        let event = AssuranceEvent(type: "generic", payload: SAMPLE_PAYLOAD, timestamp: SAMPLE_TIMESTAMP)

        // verify
        XCTAssertNotNil(event.eventID, "A random eventID should be generated")
        XCTAssertEqual("generic", event.type, "Inaccurate event type")
        XCTAssertEqual(SAMPLE_PAYLOAD, event.payload, "Inaccurate event payload")
        XCTAssertEqual(AssuranceConstants.Vendor.MOBILE, event.vendor, "vendor should default to Mobile")
        XCTAssertEqual(SAMPLE_TIMESTAMP, event.timestamp, "Inaccurate event timestamp")
    }

    func test_init_withVendor() {
        // test
        let event = AssuranceEvent(type: "generic", payload: SAMPLE_PAYLOAD, vendor: AssuranceConstants.Vendor.SDK)

        // verify
        XCTAssertNotNil(event.eventID, "A random eventID should be generated")
        XCTAssertEqual("generic", event.type, "Inaccurate event type")
        XCTAssertEqual(SAMPLE_PAYLOAD, event.payload, "Inaccurate event payload")
        XCTAssertEqual(AssuranceConstants.Vendor.SDK, event.vendor, "Inaccurate event vendor")
        XCTAssertEqual(Date().getUnixTimeInSeconds(), event.timestamp?.getUnixTimeInSeconds())
    }

    func test_init_withVendorAndTimestamp() {
        // test
        let event = AssuranceEvent(type: "generic", payload: SAMPLE_PAYLOAD, timestamp: SAMPLE_TIMESTAMP, vendor: AssuranceConstants.Vendor.SDK)

        // verify
        XCTAssertNotNil(event.eventID, "A random eventID should be generated")
        XCTAssertEqual("generic", event.type, "Inaccurate event type")
        XCTAssertEqual(SAMPLE_PAYLOAD, event.payload, "Inaccurate event payload")
        XCTAssertEqual(AssuranceConstants.Vendor.SDK, event.vendor, "Inaccurate event vendor")
        XCTAssertEqual(SAMPLE_TIMESTAMP, event.timestamp, "Inaccurate event timestamp")
        XCTAssertNil(event.metadata, "Metadata should be nil")
    }
    
    func test_init_withMetaData() {
        let event = AssuranceEvent(type: "generic", payload: SAMPLE_PAYLOAD, timestamp: SAMPLE_TIMESTAMP, metadata: SAMPLE_METADATA)
        
        // verify
        XCTAssertNotNil(event.eventID, "A random eventID should be generated")
        XCTAssertEqual("generic", event.type, "Inaccurate event type")
        XCTAssertEqual(SAMPLE_PAYLOAD, event.payload, "Inaccurate event payload")
        XCTAssertEqual(AssuranceConstants.Vendor.MOBILE, event.vendor, "Inaccurate event vendor")
        XCTAssertEqual(SAMPLE_TIMESTAMP, event.timestamp, "Inaccurate event timestamp")
        XCTAssertEqual(SAMPLE_METADATA, event.metadata, "Inaccurate metadata")
    }

    func test_init_withNilAndEmptyPayload() {
        // test
        let event1 = AssuranceEvent(type: "generic", payload: nil)
        let event2 = AssuranceEvent(type: "generic", payload: [:])

        // verify
        XCTAssertNotNil(event1, "event instance should be created with nil payload")
        XCTAssertNotNil(event2, "event instance should be created with empty payload")
        XCTAssertNil(event1.payload, "event payload should be nil")
        XCTAssertEqual(event2.payload, [:], "event payload should be empty")
    }

    func test_init_eventNumberIncrements() {
        // test
        let event1 = AssuranceEvent(type: "generic", payload: nil)
        let event2 = AssuranceEvent(type: "generic", payload: nil)
        let event3 = AssuranceEvent(type: "generic", payload: nil)
        let event4 = AssuranceEvent(type: "generic", payload: nil)

        // verify
        XCTAssertEqual(event2.eventNumber, event1.eventNumber! + 1)
        XCTAssertEqual(event3.eventNumber, event1.eventNumber! + 2)
        XCTAssertEqual(event4.eventNumber, event1.eventNumber! + 3)
    }

    /*--------------------------------------------------
     InitFromJSONData
     --------------------------------------------------*/

    func test_initFromJSONData() {
        // setup
        let data = """
                    {
                      "eventID": "someID",
                      "vendor": "someVendor",
                      "type": "someType",
                      "timestamp": 113435556,
                      "payload": {
                        "levelOneKey": {
                          "levelTwoKey": "levelTwoValue"
                        }
                      },
                      "metadata": {
                        "chunkNumber" : "20"
                     }
                    }
                   """.data(using: .utf8)!

        // test
        let event = AssuranceEvent.from(jsonData: data)!

        // verify
        XCTAssertNotNil(event, "Assurance event should be created from the json data")
        XCTAssertEqual("someID", event.eventID, "Inaccurate eventID")
        XCTAssertEqual("someVendor", event.vendor, "Inaccurate vendor")
        XCTAssertEqual("someType", event.type, "Inaccurate type")
        XCTAssertEqual(113435556, (event.timestamp?.timeIntervalSince1970 ?? -1) * 1000, accuracy: 1, "Inaccurate timestamp")
        let payloadValue = event.payload?["levelOneKey"]?.dictionaryValue!["levelTwoKey"]
        let metadataValue = event.metadata?["chunkNumber"]
        XCTAssertEqual("levelTwoValue", payloadValue as! String)
        XCTAssertEqual("20", metadataValue?.stringValue)
    }

    func test_initFromJSONData_withoutPayload() {
        // setup
        let data = """
                    {
                      "eventID": "someID",
                      "vendor": "someVendor",
                      "type": "someType",
                      "timestamp": 113435556
                    }
                   """.data(using: .utf8)!

        // test
        let event = AssuranceEvent.from(jsonData: data)!

        // verify
        XCTAssertNotNil(event, "Assurance event should be created from the json data")
        XCTAssertNil(event.payload, "Assurance event's payload should be nil")
    }

    func test_initWithJSONData_InvalidData() {
        // setup
        let data1 = "".data(using: .utf8)!
        let data2 = "I am meaningless".data(using: .utf8)!
        let dataWithNoEventID = """
                    {
                      "WrongEventIDKey": "someID", "vendor": "someVendor", "type": "someType", "timestamp": 113435556
                    }
                   """.data(using: .utf8)!
        let dataWithNoVendor = """
                    {
                      "eventID": "someID", "type": "someType", "timestamp": 113435556
                    }
                   """.data(using: .utf8)!

        let dataWithNoType = """
                    {
                      "eventID": "someID", "vendor": "someVendor", "WrongType": "someType", "timestamp": 113435556
                    }
                   """.data(using: .utf8)!

        let dataWithNoTimestamp = """
                    {
                      "eventID": "someID", "vendor": "someVendor", "type": "someType"
                    }
                   """.data(using: .utf8)!

        // test
        let event1 = AssuranceEvent.from(jsonData: data1)
        let event2 = AssuranceEvent.from(jsonData: data2)
        let event3 = AssuranceEvent.from(jsonData: dataWithNoEventID)
        let event4 = AssuranceEvent.from(jsonData: dataWithNoVendor)
        let event5 = AssuranceEvent.from(jsonData: dataWithNoType)
        let event6 = AssuranceEvent.from(jsonData: dataWithNoTimestamp)

        // verify
        XCTAssertNil(event1)
        XCTAssertNil(event2)
        XCTAssertNil(event3)
        XCTAssertNil(event4)
        XCTAssertNil(event5)
        XCTAssertNotNil(event6) // events can be created without timestamp
        XCTAssertNotNil(event6?.timestamp)
    }

    /*--------------------------------------------------
     GetCommandEventType
     --------------------------------------------------*/

    func test_getCommandEventType() {
        // setup
        let data = """
                    {
                      "eventID": "someID", "vendor": "someVendor", "timestamp": 113435556 ,
                      "type": "control",
                      "payload": {
                        "type": "screenshot"
                      }
                    }
                   """.data(using: .utf8)!

        // test
        let event = AssuranceEvent.from(jsonData: data)

        // verify
        XCTAssertEqual("screenshot", event?.commandType, "Inaccurate command type")
    }

    func test_getCommandEventType_whenNotACommand() {
        // setup
        let data = """
                    {
                      "eventID": "someID", "vendor": "someVendor", "timestamp": 113435556 ,
                      "type": "not_a_command_event",
                      "payload": {
                        "type": "screenshot"
                      }
                    }
                   """.data(using: .utf8)!

        // test
        let event = AssuranceEvent.from(jsonData: data)

        // verify
        XCTAssertNil(event?.commandType, "Command type should be nil")
    }

    func test_getCommandEventType_whenTypeUnavailable() {
        // setup
        let data = """
                    {
                      "eventID": "someID", "vendor": "someVendor", "timestamp": 113435556 ,
                      "type": "control",
                      "payload": {
                        "notype": "screenshot"
                      }
                    }
                   """.data(using: .utf8)!

        // test
        let event = AssuranceEvent.from(jsonData: data)

        // verify
        XCTAssertNil(event?.commandType, "command type should be nil")
    }

    func test_getCommandEventType_whenTypeNotAString() {
        // setup
        let data = """
                    {
                      "eventID": "someID", "vendor": "someVendor", "timestamp": 113435556 ,
                      "type": "control",
                      "payload": {
                        "type": {
                            "thisis" : "notwanted"
                        }
                      }
                    }
                   """.data(using: .utf8)!

        // test
        let event = AssuranceEvent.from(jsonData: data)

        // verify
        XCTAssertNil(event?.commandType, "Command type should be nil")
    }

    /*--------------------------------------------------
     getCommandEventDetail
     --------------------------------------------------*/

    func test_getCommandEventDetail() {
        // setup
        let data = """
                    {
                      "eventID": "someID", "vendor": "someVendor", "timestamp": 113435556 ,
                      "type": "control",
                      "payload": {
                        "type": "screenshot",
                        "detail" : {
                            "key" : "value"
                         }
                      }
                    }
                   """.data(using: .utf8)!

        // test
        let event = AssuranceEvent.from(jsonData: data)

        // verify
        XCTAssertEqual("value", event?.commandDetails!["key"] as? String, "Inaccurate command type")
    }

    func test_getCommandEventDetail_whenNotACommand() {
        // setup
        let data = """
                    {
                      "eventID": "someID", "vendor": "someVendor", "timestamp": 113435556 ,
                      "type": "notcontrol",
                      "payload": {
                        "type": "screenshot",
                        "detail" : {
                            "key" : "value"
                         }
                      }
                    }
                   """.data(using: .utf8)!

        // test
        let event = AssuranceEvent.from(jsonData: data)

        // verify
        XCTAssertNil(event?.commandDetails, "command details should be nil")
    }

    func test_getCommandEventDetail_whenDetailNotADictionary() {
        // setup
        let data = """
                    {
                      "eventID": "someID", "vendor": "someVendor", "timestamp": 113435556 ,
                      "type": "notcontrol",
                      "payload": {
                        "type": "screenshot",
                        "detail" : 333
                    }
                   """.data(using: .utf8)!

        // test
        let event = AssuranceEvent.from(jsonData: data)

        // verify
        XCTAssertNil(event?.commandDetails, "command details should be nil")
    }

    /*--------------------------------------------------
     fromMobileCoreEvent
     --------------------------------------------------*/
    func test_fromMobileCoreEvent() {
        // setup
        let sampleEventData: Dictionary = ["oneKey": "oneValue"]
        let coreEvent = Event(name: "coreEvent", type: "coreType", source: "coreSource", data: sampleEventData)
        let responseCoreEvent = coreEvent.createResponseEvent(name: "responseEvent", type: "responseEventType", source: "responseEventSource", data: nil)

        // test
        let assuranceEvent = AssuranceEvent.from(event: coreEvent)
        let assuranceEventForResponse = AssuranceEvent.from(event: responseCoreEvent)

        // verify
        XCTAssertEqual(AssuranceConstants.EventType.GENERIC, assuranceEvent.type)
        XCTAssertEqual(AssuranceConstants.Vendor.MOBILE, assuranceEvent.vendor)
        XCTAssertEqual("coreEvent", assuranceEvent.payload?[AssuranceConstants.ACPExtensionEventKey.NAME]?.stringValue)
        XCTAssertEqual("coresource", assuranceEvent.payload?[AssuranceConstants.ACPExtensionEventKey.SOURCE]?.stringValue)
        XCTAssertEqual("coretype", assuranceEvent.payload?[AssuranceConstants.ACPExtensionEventKey.TYPE]?.stringValue)
        XCTAssertEqual(sampleEventData, assuranceEvent.payload?[AssuranceConstants.ACPExtensionEventKey.DATA]?.dictionaryValue as! [String: String])
        XCTAssertEqual(coreEvent.id.uuidString, assuranceEvent.payload?[AssuranceConstants.ACPExtensionEventKey.UNIQUE_IDENTIFIER]?.stringValue)
        XCTAssertEqual(coreEvent.timestamp, assuranceEvent.payload?[AssuranceConstants.ACPExtensionEventKey.TIMESTAMP]?.value as! Date)

        // verify if the responseId is captured
        XCTAssertEqual(responseCoreEvent.responseID?.uuidString, assuranceEventForResponse.payload?[AssuranceConstants.ACPExtensionEventKey.RESPONSE_IDENTIFIER]?.stringValue)
    }
    
    func test_fromMobileCoreParentEvent() {
        let sampleEventData: Dictionary = ["oneKey": "oneValue"]
        let coreEvent = Event(name: "coreEvent", type: "coreType", source: "coreSource", data: sampleEventData)
        let childCoreEvent = coreEvent.createChainedEvent(name: "chainedEvent", type: "chainedEventType", source: "chainedEventSource", data: nil)

        // test
        let assuranceEvent = AssuranceEvent.from(event: coreEvent)
        let assuranceEventForChild = AssuranceEvent.from(event: childCoreEvent)

        // verify
        XCTAssertEqual(AssuranceConstants.EventType.GENERIC, assuranceEvent.type)
        XCTAssertEqual(AssuranceConstants.Vendor.MOBILE, assuranceEvent.vendor)
        XCTAssertEqual("coreEvent", assuranceEvent.payload?[AssuranceConstants.ACPExtensionEventKey.NAME]?.stringValue)
        XCTAssertEqual("coresource", assuranceEvent.payload?[AssuranceConstants.ACPExtensionEventKey.SOURCE]?.stringValue)
        XCTAssertEqual("coretype", assuranceEvent.payload?[AssuranceConstants.ACPExtensionEventKey.TYPE]?.stringValue)
        XCTAssertEqual(sampleEventData, assuranceEvent.payload?[AssuranceConstants.ACPExtensionEventKey.DATA]?.dictionaryValue as! [String: String])
        XCTAssertEqual(coreEvent.id.uuidString, assuranceEvent.payload?[AssuranceConstants.ACPExtensionEventKey.UNIQUE_IDENTIFIER]?.stringValue)
        XCTAssertEqual(coreEvent.timestamp, assuranceEvent.payload?[AssuranceConstants.ACPExtensionEventKey.TIMESTAMP]?.value as! Date)

        // verify if the responseId is captured
        XCTAssertEqual(childCoreEvent.parentID?.uuidString, assuranceEventForChild.payload?[AssuranceConstants.ACPExtensionEventKey.PARENT_IDENTIFIER]?.stringValue)
    }
}
