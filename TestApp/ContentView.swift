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
import AEPAssurance
import AEPCore
import AEPEdgeConsent
#if os(iOS)
import AEPMessaging
#endif
import AEPPlaces
import AEPUserProfile

import CoreLocation
import SwiftUI

let HEADING_FONT_SIZE: CGFloat = 25.0

struct SectionHeader: View {
    var title: String

    init(_ title: String) {
        self.title = title
    }

    var body: some View {
        Text(title)
            .font(.title)
            .fontWeight(.bold)
            .padding(.top)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#if os(iOS)
@available(iOS 15.0, *)
class HomePageCardCustomizer : ContentCardCustomizing {

    func customize(template: SmallImageTemplate) {
        // customize title
        template.title.font = .system(size: 16, weight: .bold)
        template.title.textColor = .black

        // customize body
        template.body?.textColor = .gray
        template.body?.font = .system(size: 13, weight: .regular)

        // customize stack structure
        template.textVStack.spacing = 10

        // customize buttons
        template.buttons?.first?.text.font = .system(size: 14)
        template.buttons?.first?.text.textColor = .white
        template.buttons?.first?.modifier = AEPViewModifier(ButtonModifier())

        // customize image
        template.image?.modifier = AEPViewModifier(ImageModifier())

        // customize rootView
        template.rootHStack.modifier = AEPViewModifier(RootHStackModifier())

    }


    struct ButtonModifier : ViewModifier {
        func body(content: Content) -> some View {
            if #available(iOS 16.0, *) {
                content
                    .background(Color.pink)
                    .cornerRadius(10)
                    .fontWeight(.semibold)
            } else {
                // Fallback on earlier versions
            }
        }
    }

    struct ImageModifier : ViewModifier {
        func body(content: Content) -> some View {
            content
                .cornerRadius(10)
        }
    }

    struct RootHStackModifier : ViewModifier {
        func body(content: Content) -> some View {
            content
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.yellow)
                .cornerRadius(15)
        }
    }
}
#endif

@available(iOS 15.0, *)
struct ContentView: View {
    #if os(iOS)
    @State var savedCards: [ContentCardUI]?
    #endif

    var body: some View {
        ZStack {
            ScrollView(.vertical) {
#if os(iOS)
                if let cards = savedCards {
                    SectionHeader("Deals")
                    ScrollView(.horizontal, showsIndicators: false) {
                        LazyHStack(spacing: 30) {
                            ForEach(cards) { card in
                                Button(action: {
                                    print(card.id)
                                    print(card.meta)
                                }) {
                                    card.view
                                }
                            }
                        }
                    }
                }
                Button(action: {
                    let homepageSurface = Surface(path: "homepage")
                    Messaging.updatePropositionsForSurfaces([homepageSurface])
                }) {
                    Text("Update props")
                }
                #endif
                AssuranceCard()
                AnalyticsCard()
                UserProfileCard()
                ConsentCard()
                PlacesCard()
                BigEventsCard()
            }
        }

        .onAppear {
            MobileCore.track(state: "Home Screen", data: nil)
            #if os(iOS)
            let homePageSurface = Surface(path: "homepage")
            Messaging.getContentCardsUI(for: homePageSurface, customizer: HomePageCardCustomizer()) { result in
                switch result {
                case .success(let cards):
                    savedCards = cards
                case .failure(let error):
                    print(error)
                }
            }
            #endif
        }
    }
}

@available(iOS 15.0, *)
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

struct YellowButtonStyle: ButtonStyle {
#if os(tvOS)
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
    }
#else
    func makeBody(configuration: Configuration) -> some View {
        HStack {
            Spacer()
            configuration.label.foregroundColor(.black)
            Spacer()
        }
        .padding()
        .background(Color.yellow.cornerRadius(8))
        .scaleEffect(configuration.isPressed ? 0.95 : 1)
    }
#endif
}

struct AssuranceCard: View {
    @State private var assuranceURL: String = ""
//    @State private var assuranceURL: String = "griffon://?adb_validation_sessionid=c0857675-4bab-4990-ba40-8781b10b415a"
    var body: some View {
        VStack {
            HStack {
                Text("Assurance: v" + Assurance.extensionVersion)
                    .padding(.leading)
                    .font(.system(size: HEADING_FONT_SIZE, weight: .heavy, design: .default))
                Spacer()
            }

            HStack {
                TextField("Copy Assurance Session URL to here", text: $assuranceURL)
                    .background(Color(.systemGray))
                    .cornerRadius(5.0)
                    .frame(height: 100)
                    .frame(height: 50)
                    .padding(EdgeInsets(top: 0, leading: 20, bottom: 0, trailing: 20))
            }

            HStack {
                Button(action: {
                    if let url = URL(string: self.assuranceURL) {
                        Assurance.startSession(url: url)
                    } else {
                        Assurance.startSession()
                    }
                }, label: {
                    Text("Start Session")
                }).padding().onReceive(NotificationCenter.default.publisher(for: .deviceDidShakeNotification)) { _ in
                    #if DEBUG
                    Assurance.startSession()
                    #endif
                }
            }
        }
    }
}

struct UserProfileCard: View {
    var body: some View {
        VStack {
            HStack {
                Text("UserProfile").padding(.leading).font(.system(size: HEADING_FONT_SIZE, weight: .heavy, design: .default))
                Spacer()
            }

            HStack {
                Button(action: {
                    let userProfile: [String: Any] = [
                        "type": "HardCore Gamer",
                        "age": 16
                    ]
                    UserProfile.updateUserAttributes(attributeDict: userProfile)
                }, label: {
                    Text("Update")
                }).padding()

                Button(action: {
                    UserProfile.removeUserAttributes(attributeNames: ["type"])
                }, label: {
                    Text("Remove")
                }).padding()
            }
        }
    }
}

struct AnalyticsCard: View {
    var body: some View {
        VStack {
            HStack {
                Text("Analytics").padding(.leading).font(.system(size: HEADING_FONT_SIZE, weight: .heavy, design: .default))
                Spacer()
            }
            HStack {
                Button(action: {
                    MobileCore.track(action: "Television Purchased", data: ["Model": "Sony"])
                }, label: {
                    Text("Track Action")
                }).padding()

                Button(action: {
                    MobileCore.track(state: "Billing Screen", data: nil)
                }, label: {
                    Text("Track State")
                }).padding()
            }
        }
    }
}

struct ConsentCard: View {
    var body: some View {
        VStack {
            HStack {
                Text("Consent").padding(.leading).font(.system(size: HEADING_FONT_SIZE, weight: .heavy, design: .default))
                Spacer()
            }

            HStack {
                Button(action: {
                    let collectConsent = ["collect": ["val": "y"]]
                    let currentConsents = ["consents": collectConsent]
                    Consent.update(with: currentConsents)
                }, label: {
                    Text("Consent Yes")
                }).padding()

                Button(action: {
                    let collectConsent = ["collect": ["val": "n"]]
                    let currentConsents = ["consents": collectConsent]
                    Consent.update(with: currentConsents)
                }, label: {
                    Text("Consent No")
                }).padding()
            }
        }
    }
}

struct PlacesCard: View {
    var body: some View {
        VStack {
            HStack {
                Text("Places").padding(.leading).font(.system(size: HEADING_FONT_SIZE, weight: .heavy, design: .default))
                Spacer()
            }

            HStack {
                Button(action: {
                    let location = CLLocation(latitude: 37.335480, longitude: -121.893028)
                    Places.getNearbyPointsOfInterest(forLocation: location, withLimit: 10) { nearbyPois, responseCode in
                        print("responseCode: \(responseCode.rawValue) \nnearbyPois: \(nearbyPois)")
                    }
                }, label: {
                    Text("Get POIs")
                })

                Button(action: {
                    let regionCenter = CLLocationCoordinate2D(latitude: 37.3255196, longitude: -121.9458237)
                    let region = CLCircularRegion(center: regionCenter, radius: 100, identifier: "dfb81b5a-1027-431a-917d-41292916d575")
                    Places.processRegionEvent(PlacesRegionEvent.entry, forRegion: region)
                }, label: {
                    Text("Entry")
                })

                Button(action: {
                    let regionCenter = CLLocationCoordinate2D(latitude: 37.3255196, longitude: -121.9458237)
                    let region = CLCircularRegion(center: regionCenter, radius: 100, identifier: "dfb81b5a-1027-431a-917d-41292916d575")
                    Places.processRegionEvent(PlacesRegionEvent.exit, forRegion: region)
                }, label: {
                    Text("Exit")
                })
            }
        }
    }
}

struct BigEventsCard: View {
    var body: some View {
        VStack {
            HStack {
                Spacer()
                Text("Big Assurance Events").padding(.leading).font(.system(size: HEADING_FONT_SIZE, weight: .heavy, design: .default))
                Spacer()
            }

            HStack {
                Button(action: {
                    guard let path = Bundle.main.path(forResource: "sample", ofType: "html") else {
                        print("[Assurance] Could not find sample.html file")
                        return
                    }
                    guard let sampleHtml = try? String(contentsOfFile: path, encoding: String.Encoding.utf8) else {
                        print("[Assurance] Could not read sample.html file")
                        return
                    }

                    // Check size before sending
                    let data = sampleHtml.data(using: .utf8) ?? Data()
                    let sizeInKB = Double(data.count) / 1024.0
                    print("[Assurance] Sending HTML data of size: \(sizeInKB) KB")

                    // Create event with detailed logging
                    let payload = ["html": sampleHtml]
                    let event = Event(name: "Huge HTML Event", type: "type", source: "source", data: payload)

                    // Log event details
                    if let eventData = try? JSONSerialization.data(withJSONObject: payload),
                       let eventJson = String(data: eventData, encoding: .utf8) {
                        print("[Assurance] Event payload size: \(Double(eventData.count) / 1024.0) KB")
                        print("[Assurance] Event JSON preview (first 200 chars): \(String(eventJson.prefix(200)))...")
                    }

                    print("[Assurance] Dispatching event through MobileCore...")
                    MobileCore.dispatch(event: event)
                    print("[Assurance] Event dispatched")

                }, label: {
                    Text("Send HTML")
                }).padding()

                Button(action: {
                    guard let path = Bundle.main.path(forResource: "sampleRules", ofType: "json") else {
                        print("[Assurance] Could not find sampleRules.json file")
                        return
                    }
                    guard let sampleJson = try? String(contentsOfFile: path, encoding: String.Encoding.utf8) else {
                        print("[Assurance] Could not read sampleRules.json file")
                        return
                    }

                    do {
                        if let json = try JSONSerialization.jsonObject(with: Data(sampleJson.utf8), options: []) as? [String: Any] {
                            // Log JSON details
                            if let jsonData = try? JSONSerialization.data(withJSONObject: json),
                               let jsonString = String(data: jsonData, encoding: .utf8) {
                                let sizeInKB = Double(jsonData.count) / 1024.0
                                print("[Assurance] JSON data size: \(sizeInKB) KB")
                                print("[Assurance] JSON preview (first 200 chars): \(String(jsonString.prefix(200)))...")
                            }

                            print("[Assurance] Creating event...")
                            let event = Event(name: "Huge JSON Event", type: "type", source: "source", data: json)

                            print("[Assurance] Dispatching event through MobileCore...")
                            MobileCore.dispatch(event: event)
                            print("[Assurance] Event dispatched")
                        }
                    } catch let error {
                        print("[Assurance] Failed to parse JSON: \(error.localizedDescription)")
                    }
                }, label: {
                    Text("Send huge rules data")
                }).padding()
            }
        }
    }
}
#if DEBUG
extension NSNotification.Name {
    public static let deviceDidShakeNotification = NSNotification.Name("MyDeviceDidShakeNotification")
}

extension UIWindow {
    open override func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
        super.motionEnded(motion, with: event)
        NotificationCenter.default.post(name: .deviceDidShakeNotification, object: event)
    }
}
#endif
