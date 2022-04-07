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
import XCTest

class ThreadSafeQueueTests: XCTestCase {

    func test_enqueue() throws {
        // setup
        let queue = ThreadSafeQueue<String>(withLimit: 10)

        // test
        queue.enqueue(newElement: "One")

        // verify
        XCTAssertEqual(1, queue.size())
    }

    func test_dequeue() throws {
        // setup
        let queue = ThreadSafeQueue<String>(withLimit: 10)
        queue.enqueue(newElement: "One")
        queue.enqueue(newElement: "Two")
        queue.enqueue(newElement: "Three")

        // test and verify
        XCTAssertEqual(3, queue.size())
        XCTAssertEqual("One", queue.dequeue())
        XCTAssertEqual("Two", queue.dequeue())
        XCTAssertEqual("Three", queue.dequeue())
        XCTAssertEqual(0, queue.size())
    }

    func test_size() throws {
        // setup
        let queue = ThreadSafeQueue<Int>(withLimit: 1000)
        for number in 1...100 {
            queue.enqueue(newElement: number)
        }

        // test and verify
        XCTAssertEqual(100, queue.size())
    }

    func test_clear() throws {
        // setup
        let queue = ThreadSafeQueue<Int>(withLimit: 10)
        for number in 1...5 {
            queue.enqueue(newElement: number)
        }

        // test and verify
        XCTAssertEqual(5, queue.size())
        queue.clear()
        XCTAssertEqual(0, queue.size())
    }

    func test_limit() throws {
        // setup
        let queue = ThreadSafeQueue<Int>(withLimit: 5)
        for number in 1...15 {
            queue.enqueue(newElement: number)
        }

        // test and verify
        XCTAssertEqual(5, queue.size())

        // dequeueing only gets the last entered elements
        for number in 11...15 {
            XCTAssertEqual(number, queue.dequeue())
        }
    }

    func test_threadSafety() throws {
        let queue = ThreadSafeQueue<String>(withLimit: 1000)
        let group = DispatchGroup()
        for _ in 0...10 {

            // Spawning threads for enqueue task
            group.enter()
            DispatchQueue.global().async {
                let sleepVal = arc4random() % 1000
                usleep(sleepVal)
                queue.enqueue(newElement: "data")
                group.leave()
            }

            // Spawning threads for dequeue task
            group.enter()
            DispatchQueue.global().async {
                let sleepVal = arc4random() % 1000
                usleep(sleepVal)
                _ = queue.dequeue()
                group.leave()
            }

            // Spawning threads for size check task
            group.enter()
            DispatchQueue.global().async {
                let sleepVal = arc4random() % 1000
                usleep(sleepVal)
                _ = queue.size()
                group.leave()
            }

            // Spawning threads for size clear task
            group.enter()
            DispatchQueue.global().async {
                let sleepVal = arc4random() % 1000
                usleep(sleepVal)
                queue.clear()
                group.leave()
            }
        }

        // verify that all the asynchronous operations are completed without crashing
        let result = group.wait(timeout: DispatchTime.now() + 3)
        XCTAssert(result == .success)
    }

}
