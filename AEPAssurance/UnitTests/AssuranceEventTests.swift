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
    private let SAMPLE_TIMESTAMP: Int64 = 22999111

    /*--------------------------------------------------
     Initilizer
     --------------------------------------------------*/
    func test_init() throws {
        // test
        let event = AssuranceEvent(type: "generic", payload: SAMPLE_PAYLOAD)

        // verify
        XCTAssertNotNil(event.eventID, "A random eventID should be generated")
        XCTAssertEqual("generic", event.type, "Inaccurate event type")
        XCTAssertEqual(SAMPLE_PAYLOAD, event.payload, "Inaccurate event payload")
        XCTAssertEqual(AssuranceConstants.Vendor.MOBILE, event.vendor, "vendor should default to Mobile")
    }

    func test_init_withTimestamp() throws {
        // test
        let event = AssuranceEvent(type: "generic", payload: SAMPLE_PAYLOAD, timestamp: SAMPLE_TIMESTAMP)

        // verify
        XCTAssertNotNil(event.eventID, "A random eventID should be generated")
        XCTAssertEqual("generic", event.type, "Inaccurate event type")
        XCTAssertEqual(SAMPLE_PAYLOAD, event.payload, "Inaccurate event payload")
        XCTAssertEqual(AssuranceConstants.Vendor.MOBILE, event.vendor, "vendor should default to Mobile")
        XCTAssertEqual(SAMPLE_TIMESTAMP, event.timestamp, "Inaccurate event timestamp")
    }

    func test_init_withVendor() throws {
        // test
        let event = AssuranceEvent(type: "generic", payload: SAMPLE_PAYLOAD, vendor: AssuranceConstants.Vendor.SDK)

        // verify
        XCTAssertNotNil(event.eventID, "A random eventID should be generated")
        XCTAssertEqual("generic", event.type, "Inaccurate event type")
        XCTAssertEqual(SAMPLE_PAYLOAD, event.payload, "Inaccurate event payload")
        XCTAssertEqual(AssuranceConstants.Vendor.SDK, event.vendor, "Inaccurate event vendor")
        XCTAssertEqual((Date().getUnixTimeInSeconds() * 1000), event.timestamp, accuracy: 100, "Timestamp should be close to current date")
    }

    func test_init_withVendorAndTimestamp() throws {
        // test
        let event = AssuranceEvent(type: "generic", payload: SAMPLE_PAYLOAD, timestamp: SAMPLE_TIMESTAMP, vendor: AssuranceConstants.Vendor.SDK)

        // verify
        XCTAssertNotNil(event.eventID, "A random eventID should be generated")
        XCTAssertEqual("generic", event.type, "Inaccurate event type")
        XCTAssertEqual(SAMPLE_PAYLOAD, event.payload, "Inaccurate event payload")
        XCTAssertEqual(AssuranceConstants.Vendor.SDK, event.vendor, "Inaccurate event vendor")
        XCTAssertEqual(SAMPLE_TIMESTAMP, event.timestamp, "Inaccurate event timestamp")
    }

    func test_init_withNilAndEmptyPayload() throws {
        // test
        let event1 = AssuranceEvent(type: "generic", payload: nil)
        let event2 = AssuranceEvent(type: "generic", payload: [:])

        // verify
        XCTAssertNotNil(event1, "event instance should be created with nil payload")
        XCTAssertNotNil(event2, "event instance should be created with empty payload")
        XCTAssertNil(event1.payload, "event payload should be nil")
        XCTAssertEqual(event2.payload, [:], "event payload should be empty")
    }

    func test_init_eventNumberIncrements() throws {
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

    func test_initFromJSONData() throws {
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
                      }
                    }
                   """.data(using: .utf8)!

        // test
        let event = AssuranceEvent.from(jsonData: data)

        // verify
        XCTAssertNotNil(event, "Assurance event should be created from the json data")
        XCTAssertEqual("someID", event?.eventID, "Inaccurate eventID")
        XCTAssertEqual("someVendor", event?.vendor, "Inaccurate vendor")
        XCTAssertEqual("someType", event?.type, "Inaccurate type")
        XCTAssertEqual(113435556, event?.timestamp, "Inaccurate timestamp")
        let payloadValue = event?.payload?["levelOneKey"]?.dictionaryValue!["levelTwoKey"]
        XCTAssertEqual("levelTwoValue", payloadValue as! String)
    }

    func test_initFromJSONData_withoutPayload() throws {
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
        let event = AssuranceEvent.from(jsonData: data)

        // verify
        XCTAssertNotNil(event, "Assurance event should be created from the json data")
        XCTAssertNil(event!.payload, "Assurance event's payload should be nil")
    }

    func test_initWithJSONData_InvalidData() throws {
        // setup
        let data1 = "".data(using: .utf8)!
        let data2 = "I am meaningless".data(using: .utf8)!
        let datawithNoEventID = """
                    {
                      "WrongEventIDKey": "someID", "vendor": "someVendor", "type": "someType", "timestamp": 113435556
                    }
                   """.data(using: .utf8)!
        let datawithNoVendor = """
                    {
                      "eventID": "someID", "type": "someType", "timestamp": 113435556
                    }
                   """.data(using: .utf8)!

        let datawithNoType = """
                    {
                      "eventID": "someID", "vendor": "someVendor", "WrongType": "someType", "timestamp": 113435556
                    }
                   """.data(using: .utf8)!

        let datawithNoTimestamp = """
                    {
                      "eventID": "someID", "vendor": "someVendor", "type": "someType"
                    }
                   """.data(using: .utf8)!

        // test
        let event1 = AssuranceEvent.from(jsonData: data1)
        let event2 = AssuranceEvent.from(jsonData: data2)
        let event3 = AssuranceEvent.from(jsonData: datawithNoEventID)
        let event4 = AssuranceEvent.from(jsonData: datawithNoVendor)
        let event5 = AssuranceEvent.from(jsonData: datawithNoType)
        let event6 = AssuranceEvent.from(jsonData: datawithNoTimestamp)

        // verify
        XCTAssertNil(event1)
        XCTAssertNil(event2)
        XCTAssertNil(event3)
        XCTAssertNil(event4)
        XCTAssertNil(event5)
        XCTAssertNil(event6)
    }

    /*--------------------------------------------------
     GetControlEventType
     --------------------------------------------------*/

    func test_getControlEventType() throws {
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
        let controlType = event?.getControlEventType()

        // verify
        XCTAssertEqual("screenshot", controlType, "Inaccurate ControlType")
    }

    func test_getControlEventType_whenNotAControlEvent() throws {
        // setup
        let data = """
                    {
                      "eventID": "someID", "vendor": "someVendor", "timestamp": 113435556 ,
                      "type": "not_a_control_event",
                      "payload": {
                        "type": "screenshot"
                      }
                    }
                   """.data(using: .utf8)!

        // test
        let event = AssuranceEvent.from(jsonData: data)
        let controlType = event?.getControlEventType()

        // verify
        XCTAssertNil(controlType, "Control type should be nil")
    }

    func test_getControlEventType_whenTypeUnavailable() throws {
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
        let controlType = event?.getControlEventType()

        // verify
        XCTAssertNil(controlType, "Control type should be nil")
    }

    func test_getControlEventType_whenTypeNotAString() throws {
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
        let controlType = event?.getControlEventType()

        // verify
        XCTAssertNil(controlType, "Control type should be nil")
    }

    /*--------------------------------------------------
     GetControlEventDetail
     --------------------------------------------------*/

    func test_getControlEventDetail() throws {
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
        let controldetail = event?.getControlEventDetail()

        // verify
        XCTAssertEqual("value", controldetail!["key"] as? String, "Inaccurate ControlType")
    }

    func test_getControlEventDetail_whenNotAControlEvent() throws {
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
        let controldetail = event?.getControlEventDetail()

        // verify
        XCTAssertNil(controldetail, "control details should be nil")
    }

    func test_getControlEventDetail_whenDetailNotADictionary() throws {
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
        let controldetail = event?.getControlEventDetail()

        // verify
        XCTAssertNil(controldetail, "control details should be nil")
    }
}
