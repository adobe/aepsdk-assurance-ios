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

struct AboutView: View {
    var body: some View {
        VStack(spacing: 40) {
            // Main app info section
            VStack(spacing: 24) {
                // App icon and title
                VStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color.red,
                                        Color.pink
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 100, height: 100)
                        
                        Image(systemName: "tv.fill")
                            .font(.system(size: 48, weight: .medium))
                            .foregroundColor(.white)
                    }
                    
                    VStack(spacing: 8) {
                        Text("iOS Sample TV App")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.white)
                        
                        Text("Adobe Experience Platform Mobile SDK")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.gray)
                    }
                }
                
                // Info section
                VStack(spacing: 16) {
                    InfoRow(label: "Version", value: "1.0.0")
                    InfoRow(label: "Platform", value: "tvOS")
                    InfoRow(label: "Build", value: "Debug")
                }
                .padding(.horizontal, 40)
            }
            
            Spacer()
            
            // About section
            VStack(spacing: 20) {
                Text("About")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                Text("This app demonstrates the Adobe Experience Platform Mobile SDK on tvOS. It includes examples of edge network communication, Analytics tracking,and SDK configuration.")
                    .font(.body)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 60)
                    .lineLimit(nil)
                
                Text("© 2025 Adobe Inc. All rights reserved.")
                    .font(.caption)
                    .foregroundColor(.gray)
                    .padding(.top, 20)
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
        .onAppear {
            // Track view appearance - placeholder
            print("About view appeared")
        }
    }
}

struct InfoRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack(spacing: 8) {
            Text("\(label):")
                .font(.body)
                .foregroundColor(.gray)
            
            Text(value)
                .font(.body)
                .foregroundColor(.white)
                .fontWeight(.medium)
            
            Spacer()
        }
    }
}

struct AboutView_Previews: PreviewProvider {
    static var previews: some View {
        AboutView()
    }
} 
