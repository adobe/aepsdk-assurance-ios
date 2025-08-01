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

// MARK: - Constants
struct AppConstants {
    static let headingFontSize: CGFloat = 30.0
    static let buttonFontSize: CGFloat = 22.0
    static let adobeRed = Color(red: 0.98, green: 0.06, blue: 0.0)
    static let adobeRedLight = Color(red: 1.0, green: 0.42, blue: 0.21)
}

// MARK: - Shared Button Style
struct TvButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack {
            Spacer()
            configuration.label
                .foregroundColor(configuration.isPressed ? .black.opacity(0.7) : .black)
                .font(.system(size: AppConstants.buttonFontSize, weight: .semibold))
            Spacer()
        }
        .padding(.vertical, 20)
        .padding(.horizontal, 30)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(configuration.isPressed ? Color.yellow.opacity(0.8) : Color.yellow)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.orange, lineWidth: configuration.isPressed ? 3 : 0)
                )
        )
        .scaleEffect(configuration.isPressed ? 0.92 : 1)
        .focusable(true)
        .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - Section Card Container
struct SectionCard<Content: View>: View {
    let title: String
    let content: Content
    
    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack(spacing: 20) {
            HStack {
                Text(title)
                    .padding(.leading)
                    .font(.system(size: AppConstants.headingFontSize, weight: .heavy, design: .default))
                    .foregroundColor(.white)
                Spacer()
            }
            
            content
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(20)
    }
}

// MARK: - Action Card
struct ActionCard: View {
    let title: String
    let description: String
    let systemImage: String
    let action: () -> Void
    @FocusState private var isFocused: Bool
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                Image(systemName: systemImage)
                    .font(.system(size: 32, weight: .medium))
                    .foregroundColor(isFocused ? .white : AppConstants.adobeRed)
                
                Text(title)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(isFocused ? .white : .white)
                    .multilineTextAlignment(.center)
                
                Text(description)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(isFocused ? Color.white.opacity(0.9) : Color.white.opacity(0.7))
                    .multilineTextAlignment(.center)
            }
            .padding(20)
            .frame(maxWidth: .infinity)
            .frame(height: 140)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        isFocused ? 
                        LinearGradient(
                            gradient: Gradient(colors: [
                                AppConstants.adobeRed.opacity(0.7),    // Lighter red
                                AppConstants.adobeRed.opacity(0.5)     // Even lighter red
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ) :
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.gray.opacity(0.15),
                                Color.gray.opacity(0.1)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(
                                isFocused ? Color.white.opacity(0.3) : AppConstants.adobeRed.opacity(0.3), 
                                lineWidth: isFocused ? 2 : 1
                            )
                    )
            )
            .scaleEffect(isFocused ? 1.05 : 1.0)
            .shadow(
                color: isFocused ? AppConstants.adobeRed.opacity(0.3) : Color.clear,
                radius: isFocused ? 8 : 0,
                x: 0,
                y: isFocused ? 4 : 0
            )
            .animation(.easeInOut(duration: 0.2), value: isFocused)
        }
        .buttonStyle(PlainButtonStyle())
        .focused($isFocused)
    }
}

// MARK: - Platform Availability Message
struct PlatformNotAvailableView: View {
    let feature: String
    let message: String
    
    var body: some View {
        Text("\(feature): Not Available on tvOS\n\n\(message)")
            .multilineTextAlignment(.center)
            .foregroundColor(.secondary)
            .padding()
    }
}

// MARK: - Loading View
struct LoadingView: View {
    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: AppConstants.adobeRed))
                .scaleEffect(1.5)
            
            Text("Loading...")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white.opacity(0.8))
        }
    }
}

// MARK: - Error View
struct ErrorView: View {
    let title: String
    let message: String
    let onRetry: (() -> Void)?
    
    init(title: String = "Something went wrong", message: String, onRetry: (() -> Void)? = nil) {
        self.title = title
        self.message = message
        self.onRetry = onRetry
    }
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 48))
                .foregroundColor(AppConstants.adobeRed)
            
            Text(title)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.white)
            
            Text(message)
                .font(.system(size: 16))
                .foregroundColor(.white.opacity(0.8))
                .multilineTextAlignment(.center)
            
            if let onRetry = onRetry {
                Button("Retry", action: onRetry)
                    .buttonStyle(TvButtonStyle())
            }
        }
        .padding()
    }
} 