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
    
    func test_initWithEncodedPayloadData() {
        // This is a real-world example of an IAM from previewOnDevice
        // Need to use string value and not read from file because of the escaped characters, reading from file will add more escaping
        let messageWithEncodedPayload = "{\"eventID\":\"293b07e7-09a2-4b19-827e-0339a6812e89\",\"vendor\":\"com.adobe.griffon.mobile\",\"type\":\"control\",\"payload\":\"{\\\"detail\\\":{\\\"eventData\\\":{\\\"triggeredconsequence\\\":{\\\"type\\\":\\\"cjmiam\\\",\\\"detail\\\":{\\\"mobileParameters\\\":{\\\"verticalAlign\\\":\\\"center\\\",\\\"dismissAnimation\\\":\\\"top\\\",\\\"verticalInset\\\":0,\\\"backdropOpacity\\\":0.2,\\\"gestures\\\":{\\\"swipeUp\\\":\\\"adbinapp://dismiss?interaction\\u003dswipeUp\\\",\\\"swipeDown\\\":\\\"adbinapp://dismiss?interaction\\u003dswipeDown\\\",\\\"swipeLeft\\\":\\\"adbinapp://dismiss?interaction\\u003dswipeLeft\\\",\\\"swipeRight\\\":\\\"adbinapp://dismiss?interaction\\u003dswipeRight\\\",\\\"tapBackground\\\":\\\"adbinapp://dismiss?interaction\\u003dtapBackground\\\"},\\\"cornerRadius\\\":15,\\\"horizontalInset\\\":0,\\\"uiTakeover\\\":true,\\\"horizontalAlign\\\":\\\"center\\\",\\\"displayAnimation\\\":\\\"top\\\",\\\"width\\\":80,\\\"backdropColor\\\":\\\"#000000\\\",\\\"height\\\":60},\\\"html\\\":\\\"\\u003c!doctype html\\u003e\\\\n\\u003chtml\\u003e\\u003chead\\u003e\\\\n    \\u003cmeta type\\u003d\\\\\\\"templateProperties\\\\\\\" name\\u003d\\\\\\\"modal\\\\\\\" label\\u003d\\\\\\\"adobe-label:modal\\\\\\\" icon\\u003d\\\\\\\"adobe-icon:modal\\\\\\\"\\u003e\\\\n    \\u003cmeta type\\u003d\\\\\\\"templateZone\\\\\\\" name\\u003d\\\\\\\"default\\\\\\\" label\\u003d\\\\\\\"Default\\\\\\\" classname\\u003d\\\\\\\"body\\\\\\\" definition\\u003d\\\\\\\"[\\u0026quot;CloseBtn\\u0026quot;, \\u0026quot;Image\\u0026quot;, \\u0026quot;Text\\u0026quot;, \\u0026quot;Buttons\\u0026quot;]\\\\\\\"\\u003e\\\\n\\\\n    \\u003cmeta type\\u003d\\\\\\\"templateDefaultAnimations\\\\\\\" displayanimation\\u003d\\\\\\\"top\\\\\\\" dismissanimation\\u003d\\\\\\\"top\\\\\\\"\\u003e\\\\n    \\u003cmeta type\\u003d\\\\\\\"templateDefaultSize\\\\\\\" width\\u003d\\\\\\\"80\\\\\\\" height\\u003d\\\\\\\"60\\\\\\\"\\u003e\\\\n    \\u003cmeta type\\u003d\\\\\\\"templateDefaultPosition\\\\\\\" verticalalign\\u003d\\\\\\\"center\\\\\\\" verticalinset\\u003d\\\\\\\"0\\\\\\\" horizontalalign\\u003d\\\\\\\"center\\\\\\\" horizontalinset\\u003d\\\\\\\"0\\\\\\\"\\u003e\\\\n    \\u003cmeta type\\u003d\\\\\\\"templateDefaultGesture\\\\\\\" swipeup\\u003d\\\\\\\"adbinapp://dismiss?interaction\\u003dswipeUp\\\\\\\" swipedown\\u003d\\\\\\\"adbinapp://dismiss?interaction\\u003dswipeDown\\\\\\\" swipeleft\\u003d\\\\\\\"adbinapp://dismiss?interaction\\u003dswipeLeft\\\\\\\" swiperight\\u003d\\\\\\\"adbinapp://dismiss?interaction\\u003dswipeRight\\\\\\\" tapbackground\\u003d\\\\\\\"adbinapp://dismiss?interaction\\u003dtapBackground\\\\\\\"\\u003e\\\\n    \\u003cmeta type\\u003d\\\\\\\"templateDefaultUiTakeover\\\\\\\" enable\\u003d\\\\\\\"true\\\\\\\"\\u003e\\\\n\\\\n    \\u003cmeta name\\u003d\\\\\\\"viewport\\\\\\\" content\\u003d\\\\\\\"width\\u003ddevice-width, initial-scale\\u003d1.0\\\\\\\"\\u003e\\\\n    \\u003cmeta charset\\u003d\\\\\\\"UTF-8\\\\\\\"\\u003e\\\\n    \\u003cstyle\\u003e\\\\n      html,\\\\n      body {\\\\n        margin: 0;\\\\n        padding: 0;\\\\n        text-align: center;\\\\n        width: 100%;\\\\n        height: 100%;\\\\n        font-family: adobe-clean, \\u0027Source Sans Pro\\u0027, -apple-system, BlinkMacSystemFont, \\u0027Segoe UI\\u0027,\\\\n          Roboto, sans-serif;\\\\n      }\\\\n      h3 {\\\\n        margin: 0.4rem auto;\\\\n      }\\\\n      p {\\\\n        margin: 0.4rem auto;\\\\n      }\\\\n\\\\n      .body {\\\\n        display: flex;\\\\n        flex-direction: column;\\\\n        background-color: #fff;\\\\n        border-radius: 0.3rem;\\\\n        color: #333333;\\\\n        width: 100vw;\\\\n        height: 100vh;\\\\n        text-align: center;\\\\n        align-items: center;\\\\n        background-size: \\u0027cover\\u0027;\\\\n      }\\\\n\\\\n      .content {\\\\n        width: 100%;\\\\n        height: 100%;\\\\n        display: flex;\\\\n        justify-content: center;\\\\n        flex-direction: column;\\\\n        position: relative;\\\\n      }\\\\n\\\\n      a {\\\\n        text-decoration: none;\\\\n      }\\\\n\\\\n      .image {\\\\n        height: 1rem;\\\\n        flex-grow: 4;\\\\n        flex-shrink: 1;\\\\n        display: flex;\\\\n        justify-content: center;\\\\n        width: 90%;\\\\n        flex-direction: column;\\\\n        align-items: center;\\\\n      }\\\\n      .image img {\\\\n        max-height: 100%;\\\\n        max-width: 100%;\\\\n      }\\\\n\\\\n      .image.empty-image {\\\\n        display: none;\\\\n      }\\\\n\\\\n      .empty-image ~ .text {\\\\n        flex-grow: 1;\\\\n      }\\\\n\\\\n      .text {\\\\n        text-align: center;\\\\n        color: #333333;\\\\n        line-height: 1.25rem;\\\\n        font-size: 0.875rem;\\\\n        padding: 0 0.8rem;\\\\n        width: 100%;\\\\n        box-sizing: border-box;\\\\n      }\\\\n      .title {\\\\n        line-height: 1.3125rem;\\\\n        font-size: 1.025rem;\\\\n      }\\\\n\\\\n      .buttons {\\\\n        width: 100%;\\\\n        display: flex;\\\\n        flex-direction: column;\\\\n        font-size: 1rem;\\\\n        line-height: 1.3rem;\\\\n        text-decoration: none;\\\\n        text-align: center;\\\\n        box-sizing: border-box;\\\\n        padding: 0.8rem;\\\\n        padding-top: 0.4rem;\\\\n        gap: 0.3125rem;\\\\n      }\\\\n\\\\n      .button {\\\\n        flex-grow: 1;\\\\n        background-color: #1473e6;\\\\n        color: #ffffff;\\\\n        border-radius: 0.25rem;\\\\n        cursor: pointer;\\\\n        padding: 0.3rem;\\\\n        gap: 0.5rem;\\\\n      }\\\\n\\\\n      .btnClose {\\\\n        color: #000000;\\\\n      }\\\\n\\\\n      .closeBtn {\\\\n        align-self: flex-end;\\\\n        color: #000000;\\\\n        width: 1.8rem;\\\\n        height: 1.8rem;\\\\n        margin-top: 1rem;\\\\n        margin-right: 0.3rem;\\\\n      }\\\\n      .closeBtn img {\\\\n        width: 100%;\\\\n        height: 100%;\\\\n      }\\\\n    \\u003c/style\\u003e\\\\n    \\u003cstyle type\\u003d\\\\\\\"text/css\\\\\\\" id\\u003d\\\\\\\"editor-styles\\\\\\\"\\u003e\\\\n\\\\n\\u003c/style\\u003e\\\\n  \\u003c/head\\u003e\\\\n\\\\n  \\u003cbody\\u003e\\\\n    \\u003cdiv class\\u003d\\\\\\\"body\\\\\\\"\\u003e\\u003cdiv class\\u003d\\\\\\\"closeBtn\\\\\\\" data-uuid\\u003d\\\\\\\"362ef3b3-41ed-4b2b-8ef6-57e332a953c8\\\\\\\" data-btn-style\\u003d\\\\\\\"plain\\\\\\\"\\u003e\\u003ca aria-label\\u003d\\\\\\\"Close\\\\\\\" class\\u003d\\\\\\\"btnClose\\\\\\\" href\\u003d\\\\\\\"adbinapp://dismiss?interaction\\u003dcancel\\\\\\\"\\u003e\\u003csvg xmlns\\u003d\\\\\\\"http://www.w3.org/2000/svg\\\\\\\" height\\u003d\\\\\\\"18\\\\\\\" viewbox\\u003d\\\\\\\"0 0 18 18\\\\\\\" width\\u003d\\\\\\\"18\\\\\\\" class\\u003d\\\\\\\"close\\\\\\\"\\u003e\\\\n  \\u003crect id\\u003d\\\\\\\"Canvas\\\\\\\" fill\\u003d\\\\\\\"#ffffff\\\\\\\" opacity\\u003d\\\\\\\"0\\\\\\\" width\\u003d\\\\\\\"18\\\\\\\" height\\u003d\\\\\\\"18\\\\\\\"\\u003e\\u003c/rect\\u003e\\\\n  \\u003cpath fill\\u003d\\\\\\\"currentColor\\\\\\\" xmlns\\u003d\\\\\\\"http://www.w3.org/2000/svg\\\\\\\" d\\u003d\\\\\\\"M13.2425,3.343,9,7.586,4.7575,3.343a.5.5,0,0,0-.707,0L3.343,4.05a.5.5,0,0,0,0,.707L7.586,9,3.343,13.2425a.5.5,0,0,0,0,.707l.707.7075a.5.5,0,0,0,.707,0L9,10.414l4.2425,4.243a.5.5,0,0,0,.707,0l.7075-.707a.5.5,0,0,0,0-.707L10.414,9l4.243-4.2425a.5.5,0,0,0,0-.707L13.95,3.343a.5.5,0,0,0-.70711-.00039Z\\\\\\\"\\u003e\\u003c/path\\u003e\\\\n\\u003c/svg\\u003e\\u003c/a\\u003e\\u003c/div\\u003e\\u003cdiv class\\u003d\\\\\\\"image\\\\\\\" data-uuid\\u003d\\\\\\\"1676d303-988b-4c8c-8e54-f7d2aa7d0adc\\\\\\\"\\u003e\\u003cimg src\\u003d\\\\\\\"https://d14dq8eoa1si34.cloudfront.net/2a6ef2f0-1167-11eb-88c6-b512a5ef09a7/urn:aaid:aem:d6c49a4a-8545-4d6d-812c-035dba81c4a6/oak:1.0::ci:b3cbed1b260ed90dff6198ff6c1d1f37/d4455e35-71bb-3bdb-9417-ed2fd5d8698b\\\\\\\" alt\\u003d\\\\\\\"\\\\\\\"\\u003e\\u003c/div\\u003e\\u003cdiv class\\u003d\\\\\\\"text\\\\\\\" data-uuid\\u003d\\\\\\\"d2bd1254-cf5c-4783-ba2f-27e8a09e2469\\\\\\\"\\u003e\\u003ch3\\u003e\\u003c/h3\\u003e\\u003cp\\u003eHello み\\u003c/p\\u003e\\u003c/div\\u003e\\u003cdiv class\\u003d\\\\\\\"buttons\\\\\\\" data-uuid\\u003d\\\\\\\"59fdd469-ac93-4c70-9d39-940834088e6c\\\\\\\"\\u003e\\u003ca class\\u003d\\\\\\\"button\\\\\\\" data-uuid\\u003d\\\\\\\"193aa7a6-fdd2-42b2-a61f-9c9a50c45acb\\\\\\\" href\\u003d\\\\\\\"adbinapp://dismiss?interaction\\u003dclicked\\\\\\\"\\u003eGreat\\u003c/a\\u003e\\u003c/div\\u003e\\u003c/div\\u003e\\\\n  \\\\n\\\\n\\u003c/body\\u003e\\u003c/html\\u003e\\\",\\\"remoteAssets\\\":[\\\"https://d14dq8eoa1si34.cloudfront.net/2a6ef2f0-1167-11eb-88c6-b512a5ef09a7/urn:aaid:aem:d6c49a4a-8545-4d6d-812c-035dba81c4a6/oak:1.0::ci:b3cbed1b260ed90dff6198ff6c1d1f37/d4455e35-71bb-3bdb-9417-ed2fd5d8698b\\\"]},\\\"id\\\":\\\"552e6082-7761-45a4-b638-075d45304898\\\"}},\\\"eventSource\\\":\\\"com.adobe.eventSource.responseContent\\\",\\\"eventType\\\":\\\"com.adobe.eventType.rulesEngine\\\",\\\"eventName\\\":\\\"Rule Consequence Event (Spoof)\\\"},\\\"type\\\":\\\"fakeEvent\\\"}\"}"
        guard let encodedData = messageWithEncodedPayload.data(using: .utf8) else {
            XCTFail("Could not convert string to data")
            return
        }
        
        let event = AssuranceEvent.from(jsonData: encodedData)
        XCTAssertNotNil(event)
        XCTAssertEqual(event?.vendor, "com.adobe.griffon.mobile")
        XCTAssertEqual(event?.type, "control")
        XCTAssertNotNil(event?.payload)
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
