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

// Navigation items for the sidebar
struct NavigationItem {
    let title: String
    let systemImage: String
    let id: String
}

struct MainNavigationView: View {
    @State private var selectedNavItem: String = "home"
    @FocusState private var isNavigationFocused: Bool
    
    // Navigation items - Clean and simple
    private let navigationItems = [
        NavigationItem(title: "Home", systemImage: "house.fill", id: "home"),
        NavigationItem(title: "Videos", systemImage: "play.fill", id: "videos"),
        NavigationItem(title: "About", systemImage: "info.circle.fill", id: "about")
    ]
    
    var body: some View {
        HStack(spacing: 0) {
            // Left Sidebar Navigation (YouTube-style)
            LeftSidebar(
                navigationItems: navigationItems,
                selectedItem: selectedNavItem,
                onItemSelected: { selectedNavItem = $0 }
            )
            .focused($isNavigationFocused)
            
            // Main content area
            VStack {
                // App header with Adobe branding
                AppHeader()
                
                // Content area based on selected navigation
                ContentArea(selectedNavItem: selectedNavItem)
            }
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 0.1, green: 0.1, blue: 0.1),
                        Color(red: 0.04, green: 0.04, blue: 0.04)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
        }
        .background(Color.black)
        .onAppear {
            // Set initial focus to navigation when view appears
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                isNavigationFocused = true
            }
        }
    }
}

struct LeftSidebar: View {
    let navigationItems: [NavigationItem]
    let selectedItem: String
    let onItemSelected: (String) -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // App title section
            VStack(alignment: .leading, spacing: 8) {
                Text("TV APP")
                    .font(.system(size: 20, weight: .black, design: .default))
                    .foregroundColor(.white)
    
                
                Rectangle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color(red: 0.98, green: 0.06, blue: 0.0), // Adobe Red
                                Color(red: 1.0, green: 0.42, blue: 0.21)   // Adobe Red Light
                            ]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: 60, height: 3)
            }
            .padding(.top, 24)
            .padding(.horizontal, 20)
            .padding(.bottom, 40)
            
            // Navigation items
            VStack(spacing: 12) {
                ForEach(navigationItems, id: \.id) { item in
                    CustomNavigationItem(
                        item: item,
                        isSelected: selectedItem == item.id,
                        onClick: { onItemSelected(item.id) }
                    )
                }
            }
            .padding(.horizontal, 20)
            
            Spacer()
        }
        .frame(width: 300)
        .background(
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.18, green: 0.18, blue: 0.18),
                    Color(red: 0.12, green: 0.12, blue: 0.12),
                    Color(red: 0.06, green: 0.06, blue: 0.06)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }
}

struct CustomNavigationItem: View {
    let item: NavigationItem
    let isSelected: Bool
    let onClick: () -> Void
    @FocusState private var isFocused: Bool
    
    var body: some View {
        Button(action: onClick) {
            HStack(spacing: 16) {
                Image(systemName: item.systemImage)
                    .font(.system(size: 28, weight: .medium))
                    .foregroundColor(
                        isFocused ? .white :
                        isSelected ? Color(red: 0.98, green: 0.06, blue: 0.0) : .white
                    )
                    .frame(width: 32)
                
                Text(item.title)
                    .font(.system(size: 22, weight: .medium))
                    .foregroundColor(
                        isFocused ? .white :
                        isSelected ? .white : Color.white.opacity(0.8)
                    )
                
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        isFocused ?
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color(red: 0.98, green: 0.06, blue: 0.0).opacity(0.25),
                                Color(red: 0.98, green: 0.06, blue: 0.0).opacity(0.18)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ) :
                        isSelected ?
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color(red: 0.98, green: 0.06, blue: 0.0).opacity(0.15),
                                Color(red: 0.98, green: 0.06, blue: 0.0).opacity(0.1)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ) :
                        LinearGradient(
                            gradient: Gradient(colors: [Color.clear, Color.clear]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(
                                isFocused ? Color(red: 0.98, green: 0.06, blue: 0.0).opacity(0.6) :
                                isSelected ? Color(red: 0.98, green: 0.06, blue: 0.0).opacity(0.4) :
                                Color.clear,
                                lineWidth: isFocused ? 2 : 1
                            )
                    )
            )
            .shadow(
                color: isFocused ? Color.black.opacity(0.2) : Color.clear,
                radius: isFocused ? 4 : 0,
                x: 0,
                y: isFocused ? 2 : 0
            )
        }
        .buttonStyle(PlainButtonStyle())
        .focused($isFocused)
        .scaleEffect(isFocused ? 1.02 : 1.0)
        .animation(.easeInOut(duration: 0.25), value: isFocused)
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
}

struct AppHeader: View {
    var body: some View {
        HStack {
            // Adobe red accent bar
            Rectangle()
                .fill(Color(red: 0.98, green: 0.06, blue: 0.0))
                .frame(width: 4, height: 40)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("iOS Sample TV App")
                    .font(.system(size: 28, weight: .heavy, design: .default))
                    .foregroundColor(.white)
    
                
                Text("Adobe Experience Platform Mobile SDK")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
            }
            
            Spacer()
        }
        .padding(.top, 36)
        .padding(.horizontal, 24)
        .padding(.bottom, 24)
    }
}

struct ContentArea: View {
    let selectedNavItem: String
    
    var body: some View {
        ScrollView {
            VStack {
                switch selectedNavItem {
                case "home":
                    HomeView()
                case "videos":
                    VideosView()
                case "about":
                    AboutView()
                default:
                    HomeView()
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 48)
        }
    }
}

#Preview {
    MainNavigationView()
} 
