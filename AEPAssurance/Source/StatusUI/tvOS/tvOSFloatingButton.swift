//
// Copyright 2024 Adobe. All rights reserved.
// This file is licensed to you under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License. You may obtain a copy
// of the License at http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software distributed under
// the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR REPRESENTATIONS
// OF ANY KIND, either express or implied. See the License for the specific language
// governing permissions and limitations under the License.
//

import SwiftUI
//
//struct tvOSFloatingButton: View {
//    var dismissAction: () -> Void
//
//    func adobeLogoImage() -> Image {
//        let imageData = Data(bytes: ActiveIcon.content, count: ActiveIcon.content.count)
//        guard let uiImage = UIImage(data: imageData) else {
//            return Image(systemName: "a.circle") // Fallback image
//        }
//        return Image(uiImage: uiImage)
//    }
//
//    var body: some View {
//        ZStack {
//            // Transparent background that doesn't intercept focus or touches
//            Color.clear
//                .allowsHitTesting(false)
//
//            VStack {
//                Spacer()
//                HStack {
//                    Spacer()
//                    Button(action: dismissAction) {
//                        VStack(spacing: 4) {
//                            adobeLogoImage()
//                                .resizable()
//                                .frame(width: 50, height: 50)
//                                .cornerRadius(4)
//
//                            Text(NSLocalizedString("status_screen_button_disconnect", value: "Disconnect", comment: ""))
//                                .font(.caption2)
//                                .lineLimit(1)
//                        }
//                        .background(Color.gray.opacity(0.8))
//                        .cornerRadius(8)
//                    }
//                }
//            }
//        }
//    }
//}
//
