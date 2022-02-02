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

struct AssuranceEventChunker {
    let CHUNK_SIZE = 30 * 1024 // 30KB

    func chunk(_ event: AssuranceEvent) -> [AssuranceEvent] {
        var chunkedEvents: [AssuranceEvent] = []

        guard let eventPayload = event.payload else {
            return chunkedEvents
        }

        let chunkID = UUID().uuidString

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .millisecondsSince1970
        let payloadData = (try? encoder.encode(eventPayload)) ?? Data()
        let payloadSize = payloadData.count

        // formula calculate total chunks (rounded up to the nearest integer)
        // totalChunks = n / d + (n % d == 0 ? 0 : 1)
        //  where
        //    n is the total payload size to be chunked
        //    d is the size of each chunk
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
            chunkedEvents.append(AssuranceEvent(type: event.type,
                                                payload: ["chunkData": AnyCodable.init(decodedChunkString)],
                                                timestamp: event.timestamp ?? Date(),
                                                vendor: event.vendor,
                                                metadata: [ AssuranceConstants.AssuranceEvent.MetadataKey.CHUNK_ID: AnyCodable.init(chunkID),
                                                            AssuranceConstants.AssuranceEvent.MetadataKey.CHUNK_TOTAL: AnyCodable.init(totalChunks),
                                                            AssuranceConstants.AssuranceEvent.MetadataKey.CHUNK_SEQUENCE: AnyCodable.init(chunkCounter)]))
        }
        return chunkedEvents
    }
}
