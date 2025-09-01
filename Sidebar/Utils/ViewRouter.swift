//
//  ViewRouter.swift
//  Sidebar
//
//  Created by Java Kanaya Prada on 01/09/25.
//

import SwiftUI

/// A router that maps SidebarItem objects to their corresponding views
struct ViewRouter {
    
    /// Map of SidebarItem to View - this is what you requested!
    /// Usage: ViewRouter.viewMap[sidebarItem] will return the appropriate view
    static let viewMap: [SidebarItem: AnyView] = [
        SidebarItem(id: 1, title: "Home", icon: "house"): AnyView(HomeView()),
        SidebarItem(id: 2, title: "Profile", icon: "person"): AnyView(ProfileView()),
        SidebarItem(id: 3, title: "Settings", icon: "gear"): AnyView(SettingsView()),
        SidebarItem(id: 4, title: "Documents", icon: "doc"): AnyView(DocumentsView()),
        SidebarItem(id: 5, title: "Favorites", icon: "heart"): AnyView(FavoritesView())
    ]
    
    /// Helper method to get a view for a specific sidebar item
    /// Returns a default view if the item is not found in the map
    static func getView(for item: SidebarItem) -> AnyView {
        return viewMap[item] ?? AnyView(DefaultDetailView(item: item))
    }
    
    /// Alternative approach using a switch statement for better performance
    /// This avoids the dictionary lookup and AnyView type erasure
    @ViewBuilder
    static func buildView(for item: SidebarItem) -> some View {
        switch item.id {
        case 1: // Home
            HomeView()
        case 2: // Profile
            ProfileView()
        case 3: // Settings
            SettingsView()
        case 4: // Documents
            DocumentsView()
        case 5: // Favorites
            FavoritesView()
        default:
            DefaultDetailView(item: item)
        }
    }
}

/// Default view shown when no specific view is mapped for a sidebar item
struct DefaultDetailView: View {
    let item: SidebarItem
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: item.icon)
                .font(.system(size: 60))
                .foregroundColor(.blue)
            
            Text(item.title)
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("This is the default view for \(item.title)")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button("Coming Soon") {
                print("Feature coming soon for \(item.title)")
            }
            .buttonStyle(.bordered)
        }
        .padding()
        .navigationTitle(item.title)
    }
}
