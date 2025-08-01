/*
 Copyright 2025 Adobe. All rights reserved.
 This file is licensed to you under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License. You may obtain a copy
 of the License at http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing, software distributed under
 the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR REPRESENTATIONS
 OF ANY KIND, either express or implied. See the License for the specific language
 governing permissions and limitations under the License.
 */

import Foundation

struct Video: Identifiable, Hashable {
    let id: String
    let title: String
    let description: String
    let thumbnailURL: String
    let videoURL: String
    let duration: Int // Duration in seconds
    let width: Int
    let height: Int
    
    // Computed property to format duration as string (for display)
    var formattedDuration: String {
        let minutes = duration / 60
        let seconds = duration % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    // Sample data using local video file
    static let sampleVideos: [Video] = [
        Video(
            id: "1",
            title: "Big Buck Bunny",
            description: "Big Buck Bunny tells the story of a giant rabbit with a heart bigger than himself.",
            thumbnailURL: "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/images/BigBuckBunny.jpg",
            videoURL: "Big Buck Bunny - FULL HD 60FPS",
            duration: 596,
            width: 1920,
            height: 1080
        )
    ]
} 