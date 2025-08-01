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

import AEPCore
import AEPEdge
import AEPEdgeIdentity
import AEPEdgeBridge
import SwiftUI

struct HomeView: View {
    var body: some View {
        VStack(spacing: 30) {
            // Quick Connect Section
            VStack(spacing: 16) {
                HStack {
                    Text("Quick Connect")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                    Spacer()
                }
                
                HStack(spacing: 16) {
                    ActionCard(
                        title: "Connect to Assurance",
                        description: "Connect to Adobe Assurance",
                        systemImage: "antenna.radiowaves.left.and.right"
                    ) {
                        // TODO: Uncomment when ready to use Assurance
                        // Assurance.startSession()
                        print("Assurance connection commented out for now")
                    }
                    
                    ActionCard(
                        title: "Send Edge Event",
                        description: "Send event using Edge.sendEvent API",
                        systemImage: "arrow.up.circle.fill"
                    ) {
                        // Send Edge event
                        let experienceEvent = ExperienceEvent(xdm: ["eventType": "TV Test Event"], data: ["platform": "tvOS"])
                        Edge.sendEvent(experienceEvent: experienceEvent)
                    }
                }
            }
            
            // Analytics Section
            SectionCard(title: "Analytics") {
                HStack(spacing: 16) {
                    ActionCard(
                        title: "Track Action",
                        description: "Track action with Analytics",
                        systemImage: "target"
                    ) {
                        MobileCore.track(action: "TV Show Watched", data: ["Show": "Apple TV+", "Genre": "Drama"])
                    }
                    
                    ActionCard(
                        title: "Track State",
                        description: "Track state with Analytics",
                        systemImage: "chart.bar.fill"
                    ) {
                        MobileCore.track(state: "TV Home Screen", data: nil)
                    }
                }
            }
            
            // Large Events Section
            SectionCard(title: "Event Chunking") {
                BigEventsCard()
            }
        }
    }
}

// MARK: - Individual Cards

struct BigEventsCard: View {
    var body: some View {
        VStack(spacing: 20) {
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                // ActionCard(
                //     title: "Small Payload",
                //     description: "Send small event",
                //     systemImage: "doc.text"
                // ) {
                //     // Send small event
                //     MobileCore.dispatch(event: Event(name: "Small Event", type: "type", source: "source", data: ["size": "small"]))
                // }
                
                // ActionCard(
                //     title: "Large Payload",
                //     description: "Send large event",
                //     systemImage: "doc.text.fill"
                // ) {
                //     // Send large HTML event
                //     sendLargeHtmlEvent()
                // }
                
                ActionCard(
                    title: "Send HTML",
                    description: "Send huge HTML event",
                    systemImage: "globe"
                ) {
                    sendLargeHtmlEvent()
                }
                
                ActionCard(
                    title: "Send JSON", 
                    description: "Send huge JSON event",
                    systemImage: "curlybraces"
                ) {
                    sendLargeJsonEvent()
                }
            }
        }
    }
    
    private func sendLargeHtmlEvent() {
        guard let path = Bundle.main.path(forResource: "sample", ofType: "html") else {
            return
        }
        let sampleHtml = try? String(contentsOfFile: path, encoding: String.Encoding.utf8)
        MobileCore.dispatch(event: Event(name: "Huge HTML Event", type: "type", source: "source", data: ["html": sampleHtml ?? ""]))
    }
    
    private func sendLargeJsonEvent() {
        let path = Bundle.main.path(forResource: "sampleRules", ofType: "json")
        guard let sampleJson = try? String(contentsOfFile: path!, encoding: String.Encoding.utf8) else {
            return
        }
        do {
            if let json = try JSONSerialization.jsonObject(with: Data(sampleJson.utf8), options: []) as? [String: Any] {
                MobileCore.dispatch(event: Event(name: "Huge JSON Event", type: "type", source: "source", data: json))
            }
        } catch _ as NSError {}
    }
}

#Preview {
    HomeView()
}
