/*
 Copyright 2024 Adobe. All rights reserved.
 This file is licensed to you under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License. You may obtain a copy
 of the License at http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing, software distributed under
 the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR REPRESENTATIONS
 OF ANY KIND, either express or implied. See the License for the specific language
 governing permissions and limitations under the License.
 */

import AEPServices
import Foundation
#if os(iOS)
import SwiftUI
#else
import TVUIKit
import SwiftUI
#endif

struct AssuranceStatusView: View {
    @ObservedObject var viewModel: AssuranceStatusViewModel

    var onDisconnect: (() -> Void)?
    var onCancel: (() -> Void)?

    init(viewModel: AssuranceStatusViewModel, onDisconnect: (() -> Void)? = nil, onCancel: (() -> Void)? = nil) {
        self.viewModel = viewModel
        self.onDisconnect = onDisconnect
        self.onCancel = onCancel
    }

    func addLog(_ message: String, visibility: AssuranceClientLogVisibility) {
        DispatchQueue.main.async {
            viewModel.addLog(message, visibility: visibility)
        }
    }

    var body: some View {
        ZStack {
            // Background
            Color(red: 28/255, green: 28/255, blue: 30/255)
                .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 20) {
                // Title
                Text("Assurance")
                    .font(.system(size: 40, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.top, 40)
                    .padding(.leading, 40)

                // Logs Section
                VStack(alignment: .leading, spacing: 10) {
                    Text("Logs")
                        .font(.system(size: 24))
                        .foregroundColor(Color(white: 0.7))
                        .padding(.leading, 40)

                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 12) {
                            ForEach(viewModel.logMessages) { message in
                                LogMessageRow(message: message)
                                    #if os(tvOS)
                                    .focusable()
                                    #endif
                            }
                        }
                        .padding(20)
                    }
                    .background(Color(red: 44/255, green: 44/255, blue: 46/255))
                    .cornerRadius(8)
                    .padding(.horizontal, 40)
                }

                // Clear Log Button
                Button(action: {
                    viewModel.logMessages.removeAll()
                }) {
                    Text("Clear Log")
                        .font(.system(size: 24))
                        .foregroundColor(.black)
                        .padding(.horizontal, 30)
                        .padding(.vertical, 15)
                        .background(Color.white)
                        .cornerRadius(12)
                }
                .padding(.leading, 40)
                #if os(tvOS)
                .buttonStyle(CardButtonStyle())
                #endif

                Spacer()

                // Bottom Buttons
                HStack {
                    Button(action: {
                        onCancel?()
                    }) {
                        Text("Cancel")
                            .font(.system(size: 24))
                            .foregroundColor(.black)
                            .padding(.horizontal, 40)
                            .padding(.vertical, 15)
                            .background(Color.white)
                            .cornerRadius(12)
                    }
                    #if os(tvOS)
                    .buttonStyle(CardButtonStyle())
                    #endif

                    Spacer()

                    Button(action: {
                        onDisconnect?()
                    }) {
                        Text("Disconnect")
                            .font(.system(size: 24))
                            .foregroundColor(.white)
                            .padding(.horizontal, 40)
                            .padding(.vertical, 15)
                            .background(Color.red)
                            .cornerRadius(12)
                    }
                    #if os(tvOS)
                    .buttonStyle(CardButtonStyle())
                    #endif
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 40)
            }
        }
    }
}

struct LogMessageRow: View {
    let message: LogMessage

    private func visibilityColor(_ visibility: AssuranceClientLogVisibility) -> Color {
        switch visibility {
        case .low:
            return Color(white: 0.7)
        case .normal:
            return .white
        case .high:
            return .yellow
        case .critical:
            return .red
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(message.message)
                .font(.system(size: 20))
                .foregroundColor(visibilityColor(message.visibility))
        }
        .padding(.vertical, 4)
    }
}

#if os(tvOS)
#Preview {
    AssuranceStatusView(viewModel: AssuranceStatusViewModel())
}
#endif
