//
//  HomeView.swift
//  Sidebar
//
//  Created by Java Kanaya Prada on 01/09/25.
//

import SwiftUI

struct HomeView: View {
  @Binding var selectedItem: SidebarItem
  
  var body: some View {
    VStack(spacing: 24) {
      // Header
      VStack(spacing: 16) {
        Image(systemName: "house.fill")
          .font(.system(size: 60))
          .foregroundColor(.blue)

        Text("Welcome Home")
          .font(.largeTitle)
          .fontWeight(.bold)
      }

      // Content
      VStack(spacing: 16) {
        Text("This is your home dashboard")
          .font(.body)
          .foregroundColor(.secondary)
          .multilineTextAlignment(.center)

        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
          DashboardCard(
            title: "Documents", 
            icon: "doc.fill", 
            color: .blue,
            action: {
              selectedItem = ViewRouter.sidebarItems.first { $0.type == .documents }!
            }
          )
          DashboardCard(
            title: "Videos", 
            icon: "play.rectangle.fill", 
            color: .green,
            action: {
              selectedItem = ViewRouter.sidebarItems.first { $0.type == .videos }!
            }
          )
          DashboardCard(
            title: "Profile", 
            icon: "person.fill", 
            color: .purple,
            action: {
              selectedItem = ViewRouter.sidebarItems.first { $0.type == .profile }!
            }
          )
          DashboardCard(
            title: "Settings", 
            icon: "gear", 
            color: .orange,
            action: {
              selectedItem = ViewRouter.sidebarItems.first { $0.type == .settings }!
            }
          )
        }
      }

      Spacer()
    }
    .padding()
    .navigationTitle("Home")
  }
}

struct DashboardCard: View {
  let title: String
  let icon: String
  let color: Color
  let action: () -> Void
  
  @State private var isHovered = false

  var body: some View {
    Button(action: action) {
      VStack(spacing: 12) {
        Image(systemName: icon)
          .font(.system(size: 30))
          .foregroundColor(color)

        Text(title)
          .font(.headline)
          .multilineTextAlignment(.center)
          .foregroundColor(.primary)
      }
      .frame(height: 100)
      .frame(maxWidth: .infinity)
      .background(color.opacity(isHovered ? 0.2 : 0.1))
      .cornerRadius(12)
      .scaleEffect(isHovered ? 1.02 : 1.0)
      .animation(.easeInOut(duration: 0.2), value: isHovered)
    }
    .buttonStyle(.plain)
    .onHover { hovering in
      isHovered = hovering
    }
  }
}

#Preview {
  NavigationView {
    HomeView(selectedItem: .constant(ViewRouter.sidebarItems.first { $0.type == .home }!))
  }
}
