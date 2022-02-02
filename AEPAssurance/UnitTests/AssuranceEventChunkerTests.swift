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

@testable import AEPAssurance
import Foundation
import XCTest
import AEPServices

class AssuranceEventChunkerTests: XCTestCase {
    let chunker = AssuranceEventChunker()
    
    // This test case wont be a real scenario within Assurance SDK.
    // As events with no payload is never passed to EventChunker.
    // Result of this test case is to make sure that Chunker doesn't break with nil payload
    func test_chunk_whenNoPayload() throws {
        // setup
        let noPayloadEvent = AssuranceEvent(type: "type", payload:nil)
        
        // test
        let chunkedEvents = chunker.chunk(noPayloadEvent)
        
        // verify
        XCTAssertEqual(0, chunkedEvents.count)
    }
    
    // This test case wont be a real scenario within Assurance SDK.
    // As events with payload size less than 30KB is never passed to EventChunker.
    // Result of this test case is to make sure that Chunker doesn't break with 20KB payload
    func test_chunk_on20KBPayload() throws {
        // prepare
        let bigString = readStringFromFile(fileName: "20KBString")
        let event = AssuranceEvent(type: "type", payload: ["largeEvent" : AnyCodable.init(bigString)])
        
        // test
        let chunkedEvents = chunker.chunk(event)
        
        // verify
        XCTAssertEqual(1, chunkedEvents.count)
    }

    
    func test_chunk_onExact30KBPayload() throws {
        // prepare
        let bigString = readStringFromFile(fileName: "30KBString")
        let event = AssuranceEvent(type: "type", payload: ["largeEvent" : AnyCodable.init(bigString)])
        
        // test
        let chunkedEvents = chunker.chunk(event)
        
        // verify
        XCTAssertEqual(1, chunkedEvents.count)
    }
    
    func test_chunk_on30KBAnd1CharacterPayload() throws {
        // prepare
        let bigString = readStringFromFile(fileName: "30KB_And_1CharacterString")
        let event = AssuranceEvent(type: "type", payload: ["largeEvent" : AnyCodable.init(bigString)])
        
        // test
        let chunkedEvents = chunker.chunk(event)
        
        // verify
        XCTAssertEqual(2, chunkedEvents.count)
    }
    
    func test_chunk_on40KBPayload() throws {
        // prepare
        let stringFromFile = readStringFromFile(fileName: "40KBString")
        let eventPayload = ["largeEvent" : AnyCodable.init(stringFromFile)]
        let event = AssuranceEvent(type: "type", payload: eventPayload, vendor: AssuranceConstants.Vendor.SDK)
        
        // test
        let chunkedEvents = chunker.chunk(event)
        
        // verify
        XCTAssertEqual(2, chunkedEvents.count)
        
        // verify the content of first chunked event
        let firstChunkedEvent = chunkedEvents[0]
        XCTAssertEqual(event.vendor, firstChunkedEvent.vendor)
        XCTAssertEqual(event.type, firstChunkedEvent.type)
        XCTAssertEqual(event.timestamp, firstChunkedEvent.timestamp)
        XCTAssertNotNil(firstChunkedEvent.eventID)
        
        // verify the content of second chunked event
        let secondChunkedEvent = chunkedEvents[1]
        XCTAssertEqual(event.vendor, secondChunkedEvent.vendor)
        XCTAssertEqual(event.type, secondChunkedEvent.type)
        XCTAssertEqual(event.timestamp, secondChunkedEvent.timestamp)
        XCTAssertNotNil(secondChunkedEvent.eventID)
        
        // verify chunk metadata
        // verify total chunk number
        XCTAssertEqual(2, secondChunkedEvent.metadata!["chunkTotal"])
        XCTAssertEqual(2, firstChunkedEvent.metadata!["chunkTotal"])
        
        // verify if the chunkID's are the same
        XCTAssertEqual(secondChunkedEvent.metadata!["chunkID"], firstChunkedEvent.metadata!["chunkID"])
        
        // verify sequence number
        XCTAssertEqual(0 ,firstChunkedEvent.metadata!["chunkSequenceNumber"])
        XCTAssertEqual(1 ,secondChunkedEvent.metadata!["chunkSequenceNumber"])
        
        // verify chunk Data
        let mergedChunkString = firstChunkedEvent.payload!["chunkData"]!.stringValue!  + secondChunkedEvent.payload!["chunkData"]!.stringValue!
        let payloadString = AnyCodable.toAnyDictionary(dictionary: eventPayload)?.jsonString
        XCTAssertEqual(payloadString, mergedChunkString)
    }
    
    func test_chunk_on100KBPayload() throws {
        // prepare
        let bigString = readStringFromFile(fileName: "100KBString")
        let event = AssuranceEvent(type: "type", payload: ["largeEvent" : AnyCodable.init(bigString)])
        
        // test
        let chunkedEvents = chunker.chunk(event)
        
        // verify
        XCTAssertEqual(4, chunkedEvents.count)
    }
    
    // This HTML sample file is approximately 40KB in size
    func test_chunk_htmlData() throws {
        // prepare
        let htmlText = readStringFromFile(fileName: "htmlSample")
        let eventPayload = ["htmlMessage" : AnyCodable.init(htmlText)]
        let event = AssuranceEvent(type: "type", payload: eventPayload)
        
        // test
        let chunkedEvents = chunker.chunk(event)
        
        // verify
        XCTAssertEqual(2, chunkedEvents.count)
        
        // verify chunk Data
        let firstChunkedEvent = chunkedEvents[0]
        let secondChunkedEvent = chunkedEvents[1]
        let mergedChunkString = firstChunkedEvent.payload!["chunkData"]!.stringValue!  + secondChunkedEvent.payload!["chunkData"]!.stringValue!
        let payloadString = AnyCodable.toAnyDictionary(dictionary: eventPayload)?.jsonString
        XCTAssertEqual(payloadString, mergedChunkString)
    }
    
    private func readStringFromFile(fileName: String) -> String {
        let bundle = Bundle(for: type(of: self))
        let path = bundle.path(forResource: fileName, ofType: "txt")!
        return (try? String(contentsOfFile: path, encoding: .utf8)) ?? ""
    }
}


extension Dictionary {
    var jsonString: String? {
        guard let theJSONData = try? JSONSerialization.data(withJSONObject: self, options: []) else {
            return nil
        }
        return String(data: theJSONData, encoding: .utf8)
    }
}
