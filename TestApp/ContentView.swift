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
import AEPPlaces
import AEPUserProfile
import CoreLocation
import SwiftUI

let HEADING_FONT_SIZE: CGFloat = 25.0

struct ContentView: View {
    var body: some View {
        ScrollView(.vertical) {
            AssuranceCard()
            AnalyticsCard()
            UserProfileCard()
            ConsentCard()
            PlacesCard()

        }
        .onAppear { MobileCore.track(state: "Home", data: nil) }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

struct YellowButtonStyle: ButtonStyle {
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
}

struct AssuranceCard: View {
    @State private var assuranceURL: String = ""
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
                    .background(Color(.systemGray6))
                    .cornerRadius(5.0)
                    .frame(height: 100)
                    .frame(height: 50)
                    .padding(EdgeInsets(top: 0, leading: 20, bottom: 0, trailing: 20))
            }

            HStack {
                Button(action: {
                    if let url = URL(string: self.assuranceURL) {
                        Assurance.startSession(url: url)
                    }
                }, label: {
                    Text("Connect")
                }).buttonStyle(YellowButtonStyle()).padding()
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
                }).buttonStyle(YellowButtonStyle()).padding()

                Button(action: {
                    UserProfile.removeUserAttributes(attributeNames: ["type"])
                }, label: {
                    Text("Remove ")
                }).buttonStyle(YellowButtonStyle()).padding()
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
                    MobileCore.track(state: "Car Purchased", data: nil)
                }, label: {
                    Text("Track Action")
                }).buttonStyle(YellowButtonStyle()).padding()

                Button(action: {
                    MobileCore.track(state: "Home Page", data: nil)
                }, label: {
                    Text("Track State")
                }).buttonStyle(YellowButtonStyle()).padding()
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
                }).buttonStyle(YellowButtonStyle()).padding()

                Button(action: {
                    let collectConsent = ["collect": ["val": "n"]]
                    let currentConsents = ["consents": collectConsent]
                    Consent.update(with: currentConsents)
                }, label: {
                    Text("Consent No")
                }).buttonStyle(YellowButtonStyle()).padding()
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
                }).buttonStyle(YellowButtonStyle())

                Button(action: {
                    let regionCenter = CLLocationCoordinate2D(latitude: 37.3255196, longitude: -121.9458237)
                    let region = CLCircularRegion(center: regionCenter, radius: 100, identifier: "dfb81b5a-1027-431a-917d-41292916d575")
                    Places.processRegionEvent(PlacesRegionEvent.entry, forRegion: region)
                }, label: {
                    Text("Entry")
                }).buttonStyle(YellowButtonStyle())

                Button(action: {
                    let regionCenter = CLLocationCoordinate2D(latitude: 37.3255196, longitude: -121.9458237)
                    let region = CLCircularRegion(center: regionCenter, radius: 100, identifier: "dfb81b5a-1027-431a-917d-41292916d575")
                    Places.processRegionEvent(PlacesRegionEvent.exit, forRegion: region)
                }, label: {
                    Text("Exit")
                }).buttonStyle(YellowButtonStyle())
            }
        }
    }
}
