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
    let ALLOWED_CHUNK_EVENT_SIZE = (Int) ((32 * 1024) * 0.75)
    
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
    // As events with payload size less than 24KB (32*0.75) is never passed to EventChunker.
    // Result of this test case is to make sure that Chunker doesn't break with 5KB payload
    func test_chunk_on5KBPayload() throws {
        // prepare
        let stringFromFile = readStringFromFile("5KBString")
        let originalEventPayload = ["payloadKey" : AnyCodable.init(stringFromFile)]
        let originalEvent = AssuranceEvent(type: "type", payload: originalEventPayload)
        
        // test
        let chunkedEvents = chunker.chunk(originalEvent)
        
        // verify
        XCTAssertEqual(1, chunkedEvents.count)
        
        // verify chunk Data
        let chunkedString = chunkedEvents[0].payload!["chunkData"]!.stringValue!
        let payloadString = AnyCodable.toAnyDictionary(dictionary: originalEventPayload)?.jsonString
        XCTAssertEqual(payloadString, chunkedString)
    }
    
    func test_chunk_on20KBPayload() throws {
        // prepare
        let stringFromFile = readStringFromFile("20KBString")
        let originalEventPayload = ["payloadKey" : AnyCodable.init(stringFromFile)]
        let originalEvent = AssuranceEvent(type: "type", payload: originalEventPayload)
        
        // test
        let chunkedEvents = chunker.chunk(originalEvent)
        
        // verify
        XCTAssertEqual(2, chunkedEvents.count)
        
        // verify the content of first chunked event
        let firstChunkedEvent = chunkedEvents[0]
        XCTAssertEqual(originalEvent.vendor, firstChunkedEvent.vendor)
        XCTAssertEqual(originalEvent.type, firstChunkedEvent.type)
        XCTAssertEqual(originalEvent.timestamp, firstChunkedEvent.timestamp)
        XCTAssertNotNil(firstChunkedEvent.eventID)
        
        // verify the content of second chunked event
        let secondChunkedEvent = chunkedEvents[1]
        XCTAssertEqual(originalEvent.vendor, secondChunkedEvent.vendor)
        XCTAssertEqual(originalEvent.type, secondChunkedEvent.type)
        XCTAssertEqual(originalEvent.timestamp, secondChunkedEvent.timestamp)
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
        let payloadString = AnyCodable.toAnyDictionary(dictionary: originalEventPayload)?.jsonString
        XCTAssertEqual(payloadString, mergedChunkString)
    }

    
    // This is an extreme case of chunking, when an 8KB empty lines files is loaded.
    // The Assurance event escapes the empty lines and the string bloats up to more than consumable socket size limit
    // This is then chunked by the chunker into appropriate sizes
    func test_chunk_EmptyLinesText() throws {
        // prepare
        let bigString = readStringFromFile("emptylines")
        let event = AssuranceEvent(type: "type", payload: ["largeEvent" : AnyCodable.init(bigString)])

        // test
        let chunkedEvents = chunker.chunk(event)

        // verify final event sizes
        XCTAssertEqual(2, chunkedEvents.count)
        XCTAssertLessThan(sizeOf(chunkedEvents[0]), ALLOWED_CHUNK_EVENT_SIZE)
        XCTAssertLessThan(sizeOf(chunkedEvents[1]), ALLOWED_CHUNK_EVENT_SIZE)
    }
    
    // This HTML sample file is approximately 40KB in size
    func test_chunk_htmlData() throws {
        // prepare
        let htmlText = readStringFromFile("htmlSample")
        let eventPayload = ["htmlMessage" : AnyCodable.init(htmlText)]
        let event = AssuranceEvent(type: "type", payload: eventPayload)

        // test
        let chunkedEvents = chunker.chunk(event)

        // verify
        XCTAssertEqual(4, chunkedEvents.count)

        // verify chunk Data
        let mergedChunkString = chunkedEvents[0].payload!["chunkData"]!.stringValue!  + chunkedEvents[1].payload!["chunkData"]!.stringValue! +
                                chunkedEvents[2].payload!["chunkData"]!.stringValue!  + chunkedEvents[3].payload!["chunkData"]!.stringValue!
        let payloadString = AnyCodable.toAnyDictionary(dictionary: eventPayload)?.jsonString
        XCTAssertEqual(payloadString, mergedChunkString)
                
        // verify chunk event sizes
        XCTAssertLessThan(sizeOf(chunkedEvents[0]), ALLOWED_CHUNK_EVENT_SIZE)
        XCTAssertLessThan(sizeOf(chunkedEvents[1]), ALLOWED_CHUNK_EVENT_SIZE)
        XCTAssertLessThan(sizeOf(chunkedEvents[2]), ALLOWED_CHUNK_EVENT_SIZE)
        XCTAssertLessThan(sizeOf(chunkedEvents[3]), ALLOWED_CHUNK_EVENT_SIZE)
    }
    
    
    func test_chunk_rulesjson() throws {
        // prepare
        let eventPayload = readJsonFromFile("rules")
        let event = AssuranceEvent(type: "type", payload: eventPayload)

        // test
        let chunkedEvents = chunker.chunk(event)

        // verify
        XCTAssertEqual(2, chunkedEvents.count)
        
        // verify chunk event sizes
        XCTAssertLessThan(sizeOf(chunkedEvents[0]), ALLOWED_CHUNK_EVENT_SIZE)
        XCTAssertLessThan(sizeOf(chunkedEvents[1]), ALLOWED_CHUNK_EVENT_SIZE)
    }


    private func readStringFromFile(_ fileName: String) -> String {
        let bundle = Bundle(for: type(of: self))
        let path = bundle.path(forResource: fileName, ofType: "txt")!
        return (try? String(contentsOfFile: path, encoding: .utf8)) ?? ""
    }
    
    private func readJsonFromFile(_ fileName: String) -> [String: AnyCodable] {
        let bundle = Bundle(for: type(of: self))
        let path = bundle.path(forResource: fileName, ofType: "json")!
        let sampleJson = try? String(contentsOfFile: path, encoding: String.Encoding.utf8)
        do {
            if let json = try JSONSerialization.jsonObject(with: Data(sampleJson!.utf8), options: []) as? [String: Any] {
                return ["rules": AnyCodable.init(json)]
            }
        } catch let error as NSError {
            return [:]        }
        return [:]
    }
    
    private func sizeOf(_ assuranceEvent: AssuranceEvent) -> Int {
        let jsonData = assuranceEvent.jsonData
        return jsonData.count
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
