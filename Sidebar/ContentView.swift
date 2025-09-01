//
//  ContentView.swift
//  Sidebar
//
//  Created by Java Kanaya Prada on 01/09/25.
//

import SwiftUI

struct ContentView: View {
    @State private var selectedItem: SidebarItem? = nil
    
    // Sample data for the sidebar
    private let sidebarItems = [
        SidebarItem(id: 1, title: "Home", icon: "house"),
        SidebarItem(id: 2, title: "Profile", icon: "person"),
        SidebarItem(id: 3, title: "Settings", icon: "gear"),
        SidebarItem(id: 4, title: "Documents", icon: "doc"),
        SidebarItem(id: 5, title: "Favorites", icon: "heart")
    ]

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

// MARK: - Sidebar Item Model
struct SidebarItem: Identifiable, Hashable {
    let id: Int
    let title: String
    let icon: String
}

// MARK: - Sidebar View
struct SidebarView: View {
    let items: [SidebarItem]
    @Binding var selectedItem: SidebarItem?
    
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
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: {
                    // Add your action here
                    print("Add button tapped")
                }) {
                    Label("Add", systemImage: "plus")
                }
            }
        }
    }
}

// MARK: - Detail View
struct DetailView: View {
    let selectedItem: SidebarItem?
    
    var body: some View {
            if let item = selectedItem {
                VStack(spacing: 20) {
                    Image(systemName: item.icon)
                        .font(.system(size: 60))
                        .foregroundColor(.blue)
                    
                    Text(item.title)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("This is the detail view for \(item.title)")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    
                    
                    // Add your custom content here
                    VStack {
                        Text("Add your custom views here")
                            .font(.caption)
                        
                        // Example of adding custom content
                        Button("Sample Action") {
                            print("Action for \(item.title)")
                        }
                        .buttonStyle(.bordered)
                    }
                    
                    Spacer()
                }
                .padding()
            } else {
                // Default state when no item is selected
                VStack(spacing: 20) {
                    Image(systemName: "sidebar.left")
                        .font(.system(size: 60))
                        .foregroundColor(.gray)
                    
                    Text("Select an item")
                        .font(.title)
                        .foregroundColor(.secondary)
                    
                    Text("Choose an item from the sidebar to view its details")
                        .font(.body)
                        .multilineTextAlignment(.center)
                }
                .padding()
            }
        }
}

#Preview {
    ContentView()
        .modelContainer(for: Item.self, inMemory: true)
}
