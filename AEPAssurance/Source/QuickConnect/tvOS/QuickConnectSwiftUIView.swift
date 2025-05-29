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
        VStack(spacing: 30) {
            // Header
            ZStack {
                Color(red: 37.0/255.0, green: 37.0/255.0, blue: 37.0/255.0)
                Text("Assurance")
                    .font(.customFont(forTextStyle: .title1, customFontName: "Helvetica-Bold"))
                    .foregroundColor(.white)
            }
            .frame(height: 60)

            // Description
            Text("Confirm connection by visiting your session's connection detail screen")
                .font(.customFont(forTextStyle: .body, customFontName: "Helvetica"))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            // Connection Image
            viewModel.connectionImage()
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(height: 200)
                .padding(.vertical, 20)

            if viewModel.showError {
                VStack(spacing: 10) {
                    Text(viewModel.errorTitleText)
                        .font(.customFont(forTextStyle: .headline, customFontName: "Helvetica-Bold"))
                        .foregroundColor(.red)

                    Text(viewModel.errorDescriptionText)
                        .font(.customFont(forTextStyle: .body, customFontName: "Helvetica"))
                        .foregroundColor(.white)
                }
                .padding()
            }

            HStack(spacing: 40) {
                Button(action: {
                    viewModel.cancelClicked()
                }) {
                    Text("Cancel")
                        .font(.customFont(forTextStyle: .headline, customFontName: "Helvetica"))
                        .foregroundColor(.white)
                        .padding()
                        .frame(width: 200)
                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.white, lineWidth: 2))
                }
                .buttonStyle(.card)

                Button(action: {
                    viewModel.connectClicked()
                }) {
                    Text(viewModel.isWaiting ? "Waiting..." : "Connect")
                        .font(.customFont(forTextStyle: .headline, customFontName: "Helvetica"))
                        .foregroundColor(.white)
                        .padding()
                        .frame(width: 200)
                        .background(viewModel.isWaiting ? Color.gray : Color(red: 20.0/256.0, green: 115.0/256.0, blue: 230.0/256.0))
                        .cornerRadius(10)
                }
                .buttonStyle(.card)
                .disabled(viewModel.isWaiting)
            }

            Spacer()

            // Adobe Logo
            viewModel.adobeLogoImage()
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(height: 50)
                .padding(.bottom, 20)
        }
        .background(Color(red: 47.0/255.0, green: 47.0/255.0, blue: 47.0/255.0))
        .onAppear {
            viewModel.displayed = true
            viewModel.initialState()
        }
    }
}

#if DEBUG
struct QuickConnectSwiftUIView_Previews: PreviewProvider {
    static var previews: some View {
        QuickConnectSwiftUIView(viewModel: QuickConnectViewModel(presentationDelegate: PreviewPresentationDelegate()))
    }
}

private class PreviewPresentationDelegate: AssurancePresentationDelegate {
    var isConnected: Bool = false

    func initializePinScreenFlow() {}
    func pinScreenConnectClicked(_ pin: String) {}
    func pinScreenCancelClicked() {}
    func disconnectClicked() {}
    func createQuickConnectSession(with sessionDetails: AssuranceSessionDetails) {}
    func quickConnectError(error: AssuranceConnectionError) {}
    func quickConnectCancelled() {}
    func quickConnectBegin() {}
}
#endif
#endif
