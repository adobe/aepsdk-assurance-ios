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

#if os(tvOS)
import SwiftUI

extension Font {
    static func customFont(forTextStyle textStyle: UIFont.TextStyle, customFontName: String) -> Font {
        let defaultUIFont = UIFont.preferredFont(forTextStyle: textStyle)
        let fontSize = defaultUIFont.pointSize
        let customUIFont = UIFont(name: customFontName, size: fontSize) ?? UIFont.systemFont(ofSize: fontSize)
        let scaledFont = UIFontMetrics(forTextStyle: textStyle).scaledFont(for: customUIFont)
        return Font(scaledFont)
    }
}

struct QuickConnectSwiftUIView: View {
    @ObservedObject var viewModel: QuickConnectViewModel

    var body: some View {
        ZStack {
            Color(red: 47.0/255.0, green: 47.0/255.0, blue: 47.0/255.0)
                .edgesIgnoringSafeArea(.all)

            VStack(spacing: 0) {
                // Header
                headerView
                    .frame(height: 60)

                // Description
                Text(NSLocalizedString("quick_connect_screen_header",
                                       value: "Confirm connection by visiting your session's connection detail screen",
                                       comment: ""))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding(20)

                viewModel.connectionImage()
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(height: 200)
                    .padding(20)

                // Error and Buttons
                VStack(spacing: 15) {
                    if viewModel.showError {
                        Text(viewModel.errorTitleText)
                            .foregroundColor(.white)
                            .font(.customFont(forTextStyle: .headline, customFontName: "Helvetica-Bold"))
                            .frame(height: 40)
                            .padding(.horizontal, 20)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        Text(viewModel.errorDescriptionText)
                            .foregroundColor(.white)
                            .font(.customFont(forTextStyle: .body, customFontName: "Helvetica"))
                            .padding(.horizontal, 20)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    HStack(spacing: 45) {
                        cancelButton
                        connectButton
                    }
                    .frame(height: 50)
                }
                .padding(.top, 20)

                Spacer()

                viewModel.adobeLogoImage()
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(height: 50)
            }
        }
        .onAppear {
            viewModel.displayed = true
            viewModel.initialState()
        }
        .transition(.move(edge: .bottom))
    }

    var headerView: some View {
        ZStack {
            Color(red: 37.0/255.0, green: 37.0/255.0, blue: 37.0/255.0)
            Text("Assurance")
                .foregroundColor(.white)
                .font(.custom("Helvetica-Bold", size: 30))
        }
    }

    var cancelButton: some View {
        Button(action: { viewModel.cancelClicked() }) {
            Text(NSLocalizedString("quick_connect_screen_button_cancel", value: "Cancel", comment: ""))
                .font(.customFont(forTextStyle: .headline, customFontName: "Helvetica"))
                .foregroundColor(.white)
                .padding(.horizontal, 25)
                .frame(height: 40)
        }
        .overlay(Capsule().stroke(Color.white, lineWidth: 2))
        .background(
            Capsule()
                .fill(Color.clear)
        )
    }

    var connectButton: some View {
        Button(action: { viewModel.connectClicked() }) {
            Text(connectButtonText)
                .font(.customFont(forTextStyle: .headline, customFontName: "Helvetica"))
                .foregroundColor(.white)
                .padding(.horizontal, 25)
                .frame(height: 40)
        }
        .background(
            Capsule()
                .fill(connectButtonBackground)
        )
        .disabled(viewModel.isWaiting)
    }

    private var connectButtonText: String {
        if viewModel.showError {
            return NSLocalizedString("quick_connect_screen_button_retry", value: "Retry", comment: "")
        } else if viewModel.isWaiting {
            return NSLocalizedString("quick_connect_screen_button_waiting", value: "Waiting..", comment: "")
        } else {
            return NSLocalizedString("quick_connect_screen_button_connect", value: "Connect", comment: "")
        }
    }

    private var connectButtonBackground: Color {
        if viewModel.isWaiting {
            return Color(red: 67.0/255.0, green: 67.0/255.0, blue: 67.0/255.0)
        } else {
            return Color(red: 20.0/255.0, green: 115.0/255.0, blue: 230.0/255.0)
        }
    }
}
#endif
