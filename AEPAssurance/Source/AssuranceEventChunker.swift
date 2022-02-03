//
// Copyright 2022 Adobe. All rights reserved.
// This file is licensed to you under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License. You may obtain a copy
// of the License at http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software distributed under
// the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR REPRESENTATIONS
// OF ANY KIND, either express or implied. See the License for the specific language
// governing permissions and limitations under the License.
//

import AEPServices
import Foundation

/// Class that brings the capability to chunk the AssuranceEvent if in need to satisfy the socket size limit.
struct AssuranceEventChunker {

    /// The maximum size of data that an `AssuranceEvent` payload can hold after chunking
    ///
    /// How did we derive to 30KB?
    ///  The maximum size of an `AssuranceEvent` to get successfully delivered through the socket is 32KB.
    ///  AssuranceEvent consist of payload (Dictionary), type(String), vendor(String), metadata (Dictionary), timestamp(Long) and EventNumber (Integer)
    ///  For the AssuranceEvent to completely fit into the maximum allowed socket size, we safely assign
    ///    30KB for payload
    ///    2KB for other fields
    let CHUNK_SIZE = (Int) ((30 * 1024) * 0.7) // 30KB

    /// Chunks the given `AssuranceEvent` into multiple socket consumable size AssuranceEvents
    ///
    /// The payload field in the `AssuranceEvent` structure has the potential to bottleneck the size limit. Hence only the payload is chopped into multiple smaller chunks.
    /// Once the payload is chunked, then the chunked data is added in the payload of each AssuranceEvent under the key "chunkData".
    /// And chunked details are added to the metadata field of the Assurance Event. The chunk details comprises of
    ///   1. chunkId - Unique Id representing all the chunks of a single event.
    ///   2. chunkTotal - The total number of chunks to define the original event
    ///   3. chunkSequenceNumber - Integer Value representing the sequence of chunks
    ///
    /// - Parameter event: An `AssuranceEvent` that is over the socket size limit that needs to be chunked
    /// - Returns: An array of chunked AssuranceEvents
    func chunk(_ event: AssuranceEvent) -> [AssuranceEvent] {
        var chunkedEvents: [AssuranceEvent] = []

        guard let eventPayload = event.payload else {
            return [event]
        }

        /// An unique ID representing this set of chunked events
        let chunkID = UUID().uuidString

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .millisecondsSince1970
        let payloadData = (try? encoder.encode(eventPayload)) ?? Data()
        let payloadSize = payloadData.count
        print("Peaks------  Original Event Payload Size: \(payloadSize)")

        /// formula calculate total chunks (rounded up to the nearest integer)
        /// totalChunks = n / d + (n % d == 0 ? 0 : 1)
        ///  where:
        ///    n is the total payload size to be chunked
        ///    d is the size of each chunk
        let totalChunks = payloadSize / CHUNK_SIZE + ((payloadSize % CHUNK_SIZE) == 0 ? 0 : 1)
        for chunkCounter in 0..<totalChunks {
            var chunk: Data
            let chunkBase = chunkCounter * CHUNK_SIZE
            var diff = CHUNK_SIZE
            if chunkCounter == totalChunks - 1 {
                diff = payloadSize - chunkBase
            }
            let range: Range<Data.Index> = chunkBase..<(chunkBase + diff)
            chunk = payloadData.subdata(in: range)
            
            let decodedChunkString = String(decoding: chunk, as: UTF8.self)
            print("Peaks------  Chunked Event Payload Size: \(decodedChunkString.utf8.count)")
                        
            chunkedEvents.append(AssuranceEvent(type: event.type,
                                                payload: [AssuranceConstants.AssuranceEvent.PayloadKey.CHUNK_DATA: AnyCodable.init(decodedChunkString)],
                                                timestamp: event.timestamp ?? Date(),
                                                vendor: event.vendor,
                                                metadata: [ AssuranceConstants.AssuranceEvent.MetadataKey.CHUNK_ID: AnyCodable.init(chunkID),
                                                            AssuranceConstants.AssuranceEvent.MetadataKey.CHUNK_TOTAL: AnyCodable.init(totalChunks),
                                                            AssuranceConstants.AssuranceEvent.MetadataKey.CHUNK_SEQUENCE: AnyCodable.init(chunkCounter)]))
        }
        return chunkedEvents
    }
}
