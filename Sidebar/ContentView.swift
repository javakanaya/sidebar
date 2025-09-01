//
//  ContentView.swift
//  Sidebar
//
//  Created by Java Kanaya Prada on 01/09/25.
//

import SwiftUI

struct ContentView: View {
    // Sample data for the sidebar
    private let sidebarItems = [
        SidebarItem(id: 1, title: "Home", icon: "house"),
        SidebarItem(id: 2, title: "Profile", icon: "person"),
        SidebarItem(id: 3, title: "Settings", icon: "gear"),
        SidebarItem(id: 4, title: "Documents", icon: "doc"),
        SidebarItem(id: 5, title: "Favorites", icon: "heart")
    ]
    
    @State private var selectedItem: SidebarItem
    
    init() {
        // Set default selected item to the first item
        _selectedItem = State(initialValue: sidebarItems[0])
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

// MARK: - Sidebar Item Model
struct SidebarItem: Identifiable, Hashable {
    let id: Int
    let title: String
    let icon: String
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
    let selectedItem: SidebarItem
    
    var body: some View {
        VStack(spacing: 20) {
            // Header Section
            VStack(spacing: 16) {
                Image(systemName: selectedItem.icon)
                    .font(.system(size: 60))
                    .foregroundColor(.blue)
                
                Text(selectedItem.title)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("This is the detail view for \(selectedItem.title)")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Spacer()
            
            // Custom Content Section
            VStack(spacing: 16) {
                Text("Add your custom views here")
                    .font(.caption)
                
                Button("Sample Action") {
                    print("Action for \(selectedItem.title)")
                }
                .buttonStyle(.bordered)
            }
            
            Spacer()
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    ContentView()
}
