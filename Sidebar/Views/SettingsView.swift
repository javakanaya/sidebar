//
//  SettingsView.swift
//  Sidebar
//
//  Created by Java Kanaya Prada on 01/09/25.
//

import SwiftUI

struct SettingsView: View {
    @State private var notificationsEnabled = true
    @State private var darkModeEnabled = false
    @State private var autoSave = true
    @State private var selectedLanguage = "English"
    
    private let languages = ["English", "Spanish", "French", "German", "Japanese"]
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 16) {
                Image(systemName: "gear")
                    .font(.system(size: 60))
                    .foregroundColor(.blue)
                
                Text("Settings")
                    .font(.largeTitle)
                    .fontWeight(.bold)
            }
            .padding(.bottom, 32)
            
            // Settings List
            List {
                Section("Preferences") {
                    SettingsToggleRow(
                        title: "Enable Notifications",
                        icon: "bell.fill",
                        isOn: $notificationsEnabled
                    )
                    
                    SettingsToggleRow(
                        title: "Dark Mode",
                        icon: "moon.fill",
                        isOn: $darkModeEnabled
                    )
                    
                    SettingsToggleRow(
                        title: "Auto Save",
                        icon: "square.and.arrow.down.fill",
                        isOn: $autoSave
                    )
                }
                
                Section("Language") {
                    HStack {
                        Image(systemName: "globe")
                            .foregroundColor(.blue)
                            .frame(width: 20)
                        
                        Text("Language")
                        
                        Spacer()
                        
                        Picker("Language", selection: $selectedLanguage) {
                            ForEach(languages, id: \.self) { language in
                                Text(language).tag(language)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                    }
                }
                
                Section("About") {
                    SettingsNavigationRow(title: "Privacy Policy", icon: "hand.raised.fill")
                    SettingsNavigationRow(title: "Terms of Service", icon: "doc.text.fill")
                    SettingsNavigationRow(title: "Help & Support", icon: "questionmark.circle.fill")
                }
            }
        }
        .padding(.top)
        .navigationTitle("Settings")
    }
}

struct SettingsToggleRow: View {
    let title: String
    let icon: String
    @Binding var isOn: Bool
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 20)
            
            Text(title)
            
            Spacer()
            
            Toggle("", isOn: $isOn)
        }
    }
}

struct SettingsNavigationRow: View {
    let title: String
    let icon: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 20)
            
            Text(title)
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

#Preview {
    NavigationView {
        SettingsView()
    }
}
