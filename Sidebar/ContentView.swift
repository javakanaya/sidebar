//
//  ContentView.swift
//  Sidebar
//
//  Created by Java Kanaya Prada on 01/09/25.
//

import SwiftUI

struct ContentView: View {
  // Use the centralized sidebar items from ViewRouter
  private let sidebarItems = ViewRouter.sidebarItems

  @State private var selectedItem: SidebarItem

  init(initialSelectedItem: SidebarItem? = nil) {
    // Set default selected item to the provided item or first item (Home)
    _selectedItem = State(initialValue: initialSelectedItem ?? ViewRouter.sidebarItems[0])
  }

  var body: some View {
    NavigationSplitView {
      // Sidebar (Left Column)
      SidebarView(items: sidebarItems, selectedItem: $selectedItem)
    } detail: {
      // Detail View (Right Column)
      DetailView(selectedItem: selectedItem)
    }
  }
}

// MARK: - Sidebar View

struct SidebarView: View {
  let items: [SidebarItem]
  @Binding var selectedItem: SidebarItem

  var body: some View {
    List(items, id: \.self, selection: $selectedItem) { item in
      NavigationLink(value: item) {
        HStack {
          Image(systemName: item.icon)
            .foregroundColor(.blue)
            .frame(width: 20)
          Text(item.title)
        }
      }
    }
    .navigationTitle("Sidebar")
    .navigationSplitViewColumnWidth(min: 200, ideal: 250, max: 300)
  }
}

// MARK: - Detail View

struct DetailView: View {
  let selectedItem: SidebarItem

  var body: some View {
    // Use the ViewRouter to get the appropriate view for the selected item
    ViewRouter.buildView(for: selectedItem)
  }
}

#Preview {
  ContentView()
}

#Preview("Profile Selected") {
  ContentView(initialSelectedItem: ViewRouter.sidebarItems.first { $0.type == .profile })
}

#Preview("Settings Selected") {
  ContentView(initialSelectedItem: ViewRouter.sidebarItems.first { $0.type == .settings })
}
