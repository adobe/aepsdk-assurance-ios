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
import Combine

#if os(iOS) || os(tvOS)
import AVFoundation
import MediaPlayer
import AEPEdgeMedia
#endif

struct VideosView: View {
    @State private var player: AVPlayer? = nil
    @State private var isPlaying = false
    @State private var currentTime: Double = 0
    @State private var duration: Double = 0
    @State private var timeObserver: Any?
    @State private var cancellables = Set<AnyCancellable>()
    @State private var showControls = true
    @FocusState private var isPlayButtonFocused: Bool
    @Namespace private var focusNamespace
    
    // Adobe Media tracking
    @State private var mediaTracker: MediaTracker?
    @State private var isMediaSessionActive = false
    
    // Video details
    private let videoTitle = "Big Buck Bunny"
    private let videoDescription = "A large and lovable rabbit deals with three tiny bullies, led by a flying squirrel, who are determined to squelch his happiness."
    private let videoDuration = "9:56"
    
    var body: some View {
        VStack(spacing: 20) {
            // Video info
            VStack(spacing: 6) {
                Text(videoTitle)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                Text(videoDescription)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                    .lineLimit(2)
                
                Text("Duration: \(videoDuration)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            // Video player with custom controls
            if let player = player {
                VStack(spacing: 16) {
                    // Video player view with overlay
                    ZStack {
                        VideoPlayer(player: player)
                            .frame(height: 400)
                            .cornerRadius(12)
                            .disabled(true) // Disable built-in controls
                        
                        // Custom controls overlay
                        if showControls {
                            VStack {
                                Spacer()
                                
                                // Simple control bar
                                VStack(spacing: 12) {
                                    // Time display
                                    HStack {
                                        Text(formatTime(currentTime))
                                            .font(.caption)
                                            .foregroundColor(.white)
                                        Spacer()
                                        Text(formatTime(duration))
                                            .font(.caption)
                                            .foregroundColor(.white)
                                    }
                                    
                                    // Play/Pause button only
                                    Button(action: togglePlayPause) {
                                        Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
                                            .font(.caption2)
                                            .foregroundColor(.white)
                                            .padding(4)
                                            .background(
                                                RoundedRectangle(cornerRadius: 4)
                                                    .fill(isPlayButtonFocused ? Color.white.opacity(0.2) : Color.clear)
                                                    .overlay(
                                                        RoundedRectangle(cornerRadius: 4)
                                                            .stroke(isPlayButtonFocused ? Color.white : Color.clear, lineWidth: 1)
                                                    )
                                            )
                                            .scaleEffect(isPlayButtonFocused ? 1.05 : 1.0)
                                            .animation(.easeInOut(duration: 0.2), value: isPlayButtonFocused)
                                    }
                                    .focused($isPlayButtonFocused)
                                    .focusable(true)
                                    #if os(tvOS)
                                    .onMoveCommand { direction in
                                        if direction == .left {
                                            isPlayButtonFocused = false
                                        }
                                    }
                                    #endif
                                }
                                .padding(.horizontal, 20)
                                .padding(.vertical, 16)
                                .background(
                                    LinearGradient(
                                        gradient: Gradient(colors: [Color.black.opacity(0.0), Color.black.opacity(0.7)]),
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                            }
                        }
                    }
                    .cornerRadius(12)
                    .padding(.horizontal)
                    .onTapGesture {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            showControls.toggle()
                        }
                    }
                }
            } else {
                // Loading placeholder
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.gray.opacity(0.3))
                    .frame(height: 400)
                    .overlay(
                        VStack {
                            ProgressView()
                                .scaleEffect(1.5)
                                .padding()
                            Text("Loading video...")
                                .foregroundColor(.secondary)
                        }
                    )
                    .padding(.horizontal)
            }
            
            Spacer()
        }
        .padding()
        .onAppear {
            loadVideo()
            // Set focus to play button after a brief delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isPlayButtonFocused = true
            }
        }
        .onDisappear {
            // Pause video when leaving the view
            player?.pause()
            isPlaying = false
            
            removeTimeObserver()
            teardownRemoteControl()
            
            // End Adobe Media session (no pause tracking since session is ending)
            if isMediaSessionActive {
                mediaTracker?.trackSessionEnd()
                isMediaSessionActive = false
                print("Adobe Media session ended (view disappeared)")
            }
        }
        .onChange(of: isPlayButtonFocused) { focused in
            if focused {
                showControls = true
            }
        }
        #if os(tvOS)
        .focusScope(focusNamespace)
        .onExitCommand {
            isPlayButtonFocused = false
        }
        #endif
    }
    
    private func loadVideo() {
        print("Loading video: \(videoTitle)")
        
        // Configure audio session to reduce simulator warnings
        #if os(tvOS)
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playback, mode: .moviePlayback, options: [])
            try audioSession.setActive(true)
        } catch {
            print("Audio session configuration warning: \(error.localizedDescription)")
        }
        #endif

        // Try different approaches to load the video file
        var videoUrl: URL?
        
        // First, try to load from the main bundle root
        videoUrl = Bundle.main.url(forResource: "Big Buck Bunny - FULL HD 60FPS", withExtension: "mp4")
        
        // If not found, try in subdirectory
        if videoUrl == nil {
            videoUrl = Bundle.main.url(forResource: "Big Buck Bunny - FULL HD 60FPS", withExtension: "mp4", subdirectory: "Views/Videos/src")
        }
        
        // If still not found, try without subdirectory path
        if videoUrl == nil {
            videoUrl = Bundle.main.url(forResource: "Big Buck Bunny - FULL HD 60FPS", withExtension: "mp4", subdirectory: "src")
        }
        
        if let url = videoUrl {
            player = AVPlayer(url: url)
            print("Using local video file: \(url)")
        } else {
            print("Local video not found in bundle. Trying remote URL as fallback.")
            // Fallback to remote URL
            if let remoteUrl = URL(string: "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4") {
                player = AVPlayer(url: remoteUrl)
                print("Using remote video URL: \(remoteUrl)")
            } else {
                print("Failed to create remote URL.")
                return
            }
        }

        // Configure player for better tvOS compatibility
        player?.automaticallyWaitsToMinimizeStalling = true
        player?.preventsDisplaySleepDuringVideoPlayback = true
        
        // Configure audio session to reduce simulator warnings
        #if targetEnvironment(simulator)
        // In simulator, use a simpler audio configuration
        player?.volume = 1.0
        player?.allowsExternalPlayback = false
        #else
        // On device, use full capabilities
        player?.allowsExternalPlayback = true
        #endif

        setupTimeObserver()
        setupDuration()
        setupRemoteControl()
        
        // Initialize Adobe Media tracking
        initializeAdobeMediaTracking()
        
        print("AVPlayer created successfully for: \(videoTitle)")
    }
    
    private func setupTimeObserver() {
        guard let player = player else { return }
        
        let interval = CMTime(seconds: 0.1, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        timeObserver = player.addPeriodicTimeObserver(forInterval: interval, queue: .main) { time in
            currentTime = time.seconds
            
            // Update play state
            if player.rate > 0 {
                isPlaying = true
            } else {
                isPlaying = false
            }
            
            // Update Adobe Media playhead
            if isMediaSessionActive {
                mediaTracker?.updateCurrentPlayhead(time: Int(currentTime))
            }
        }
    }
    
    private func setupDuration() {
        guard let player = player else { return }
        
        // Observe when the player item is ready
        if let currentItem = player.currentItem {
            let keyPath = \AVPlayerItem.status
            currentItem.publisher(for: keyPath)
                .sink { status in
                    if status == .readyToPlay {
                        duration = currentItem.duration.seconds
                    }
                }
                .store(in: &cancellables)
        }
    }
    
    private func removeTimeObserver() {
        if let timeObserver = timeObserver {
            player?.removeTimeObserver(timeObserver)
            self.timeObserver = nil
        }
    }
    
    private func togglePlayPause() {
        guard let player = player else { return }
        
        if isPlaying {
            player.pause()
            if isMediaSessionActive {
                mediaTracker?.trackPause()
                print("Adobe Media: Tracked pause")
            }
        } else {
            player.play()
            if isMediaSessionActive {
                mediaTracker?.trackPlay()
                print("Adobe Media: Tracked play")
            }
        }
    }
    
    private func seekToTime(_ time: Double) {
        guard let player = player else { return }
        let targetTime = CMTime(seconds: time, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        player.seek(to: targetTime)
    }
    
    private func formatTime(_ time: Double) -> String {
        guard !time.isNaN && !time.isInfinite else { return "0:00" }
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    private func setupRemoteControl() {
        #if os(tvOS)
        guard let currentPlayer = player else { return }
        
        // Enable remote control events
        UIApplication.shared.beginReceivingRemoteControlEvents()
        
        // Set up remote control target
        let commandCenter = MPRemoteCommandCenter.shared()
        
        // Play command
        commandCenter.playCommand.isEnabled = true
        commandCenter.playCommand.addTarget { _ in
            currentPlayer.play()
            return .success
        }
        
        // Pause command
        commandCenter.pauseCommand.isEnabled = true
        commandCenter.pauseCommand.addTarget { _ in
            currentPlayer.pause()
            return .success
        }
        
        // Toggle play/pause command
        commandCenter.togglePlayPauseCommand.isEnabled = true
        commandCenter.togglePlayPauseCommand.addTarget { _ in
            if currentPlayer.rate > 0 {
                currentPlayer.pause()
            } else {
                currentPlayer.play()
            }
            return .success
        }
        #endif
    }
    
    private func teardownRemoteControl() {
        #if os(tvOS)
        // Disable remote control events
        UIApplication.shared.endReceivingRemoteControlEvents()
        
        // Remove all targets from command center
        let commandCenter = MPRemoteCommandCenter.shared()
        commandCenter.playCommand.removeTarget(nil)
        commandCenter.pauseCommand.removeTarget(nil)
        commandCenter.togglePlayPauseCommand.removeTarget(nil)
        #endif
    }
    
    private func initializeAdobeMediaTracking() {
        print("Initializing Adobe Media tracking")
        
        mediaTracker = Media.createTracker()
        
        let mediaInfo: [String: Any] = [
            "name": videoTitle,
            "id": "big-buck-bunny-hd", 
            "length": 596,
            "streamType": "vod",
            "mediaType": "video"
        ]
        
        let metadata: [String: String] = [
            "a.media.show": "iOS TV Test App",
            "a.media.season": "1",
            "a.media.episode": "big-buck-bunny-hd",
            "a.media.genre": "Technology",
            "a.media.network": "Adobe Experience Platform"
        ]
        
        mediaTracker?.trackSessionStart(info: mediaInfo, metadata: metadata)
        isMediaSessionActive = true
        
        print("Adobe Media session started")
    }
}

#Preview {
    VideosView()
} 
