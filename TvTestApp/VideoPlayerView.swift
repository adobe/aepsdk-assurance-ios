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

import SwiftUI
import AVKit

struct VideoPlayerView: View {
    let player: AVPlayer
    let onDismiss: () -> Void
    
    @State private var showError = false
    @State private var errorMessage = ""
    
    var body: some View {
        ZStack {
            VideoPlayer(player: player)
                .onAppear {
                    player.play()
                    NotificationCenter.default.addObserver(forName: .AVPlayerItemFailedToPlayToEndTime, object: player.currentItem, queue: .main) { notification in
                        if let error = notification.userInfo?[AVPlayerItemFailedToPlayToEndTimeErrorKey] as? Error {
                            errorMessage = error.localizedDescription
                        } else {
                            errorMessage = "Unknown playback error."
                        }
                        showError = true
                    }
                }
                .onDisappear {
                    player.pause()
                    NotificationCenter.default.removeObserver(self)
                }
                .ignoresSafeArea()
            
            if showError {
                VStack(spacing: 20) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.yellow)
                    Text("Playback Error")
                        .font(.title2)
                        .bold()
                    Text(errorMessage)
                        .font(.body)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.secondary)
                    Button("Close") {
                        onDismiss()
                    }
                    .padding()
                    .background(Color.gray.opacity(0.8))
                    .cornerRadius(10)
                }
                .padding()
                .background(Color.black.opacity(0.8))
                .cornerRadius(20)
            }
        }
    }
}

// Wrapper view for easier SwiftUI integration
struct VideoPlayerContainerView: View {
    let player: AVPlayer
    let onDismiss: () -> Void
    
    var body: some View {
        VideoPlayerView(player: player, onDismiss: onDismiss)
    }
}

#Preview {
    let player = AVPlayer(url: URL(string: "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4")!)
    VideoPlayerContainerView(player: player, onDismiss: {})
} 