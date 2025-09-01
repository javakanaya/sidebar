//
//  ViewRouter.swift
//  Sidebar
//
//  Created by Java Kanaya Prada on 01/09/25.
//

import SwiftUI

/// Enum defining all available sidebar item types
enum SidebarItemType: String, CaseIterable, Identifiable {
    case home = "home"
    case profile = "profile"
    case settings = "settings"
    case documents = "documents"
    case favorites = "favorites"
    
    var id: String { self.rawValue }
    
    /// Display title for each sidebar item
    var title: String {
        switch self {
        case .home: return "Home"
        case .profile: return "Profile"
        case .settings: return "Settings"
        case .documents: return "Documents"
        case .favorites: return "Favorites"
        }
    }
    
    /// SF Symbol icon for each sidebar item
    var icon: String {
        switch self {
        case .home: return "house"
        case .profile: return "person"
        case .settings: return "gear"
        case .documents: return "doc"
        case .favorites: return "heart"
        }
    }
}

/// A router that maps SidebarItem objects to their corresponding views
struct ViewRouter {
    
    /// Generates all sidebar items from the enum
    static let sidebarItems: [SidebarItem] = SidebarItemType.allCases.map { type in
        SidebarItem(type: type)
    }
    
    /// Primary method to build views using @ViewBuilder for optimal performance
    @ViewBuilder
    static func buildView(for item: SidebarItem) -> some View {
        switch item.type {
        case .home:
            HomeView()
        case .profile:
            ProfileView()
        case .settings:
            SettingsView()
        case .documents:
            DocumentsView()
        case .favorites:
            FavoritesView()
        }
    }
}

/// Updated SidebarItem model using enum-based approach
struct SidebarItem: Identifiable, Hashable {
    let type: SidebarItemType
    
    var id: String { type.id }
    var title: String { type.title }
    var icon: String { type.icon }
}
