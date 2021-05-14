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
import AEPUserProfile
import AEPCore
import SwiftUI


struct ContentView: View {
    var body: some View {
        VStack {
            Text("Assurance Version: v" + Assurance.extensionVersion).padding()
            HStack {
                Text("Analytics").padding(.leading).font(.system(size: 25, weight: .heavy, design: .default))
                Spacer()
            }
            
            HStack {
                Button(action: {
                    MobileCore.track(state: "Fabulous action", data: nil)
                }, label: {
                    Text("Track Action")
                }).buttonStyle(RoundedRectangleButtonStyle()).padding()
                
                Button(action: {
                    MobileCore.track(state: "Amazing state", data: nil)
                }, label: {
                    Text("Track State")
                }).buttonStyle(RoundedRectangleButtonStyle()).padding()
            }
            
            HStack {
                Text("UserProfile").padding(.leading).font(.system(size: 25, weight: .heavy, design: .default))
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
                }).buttonStyle(RoundedRectangleButtonStyle()).padding()
                
                Button(action: {
                    UserProfile.removeUserAttributes(attributeNames: ["type"])
                }, label: {
                    Text("Remove ")
                }).buttonStyle(RoundedRectangleButtonStyle()).padding()
            }
            
            HStack {
                Text("Consent").padding(.leading).font(.system(size: 25, weight: .heavy, design: .default))
                Spacer()
            }
            
            HStack {
                Button(action: {

                }, label: {
                    Text("Consent Yes")
                }).buttonStyle(RoundedRectangleButtonStyle()).padding()
                
                Button(action: {
                    
                }, label: {
                    Text("Consent No")
                }).buttonStyle(RoundedRectangleButtonStyle()).padding()
            }
            
            HStack {
                Text("Places").padding(.leading).font(.system(size: 25, weight: .heavy, design: .default))
                Spacer()
            }
            
            HStack {
                Button(action: {

                }, label: {
                    Text("Get POIs")
                }).buttonStyle(RoundedRectangleButtonStyle())
                
                Button(action: {
                    
                }, label: {
                    Text("Places Entry")
                }).buttonStyle(RoundedRectangleButtonStyle())
                
                Button(action: {
                    
                }, label: {
                    Text("Places Exit")
                }).buttonStyle(RoundedRectangleButtonStyle())
            }
        }
        
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

struct RoundedRectangleButtonStyle: ButtonStyle {
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
