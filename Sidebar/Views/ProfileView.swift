//
//  ProfileView.swift
//  Sidebar
//
//  Created by Java Kanaya Prada on 01/09/25.
//

import SwiftUI

struct ProfileView: View {
  @State private var userName = "John Doe"
  @State private var userEmail = "john.doe@example.com"
  @State private var bio = "iOS Developer passionate about creating great user experiences."

  var body: some View {
    ScrollView {
      VStack(spacing: 24) {
        // Header
        VStack(spacing: 16) {
          Image(systemName: "person.circle.fill")
            .font(.system(size: 80))
            .foregroundColor(.blue)

          Text("Profile")
            .font(.largeTitle)
            .fontWeight(.bold)
        }

        // Profile Information
        VStack(spacing: 20) {
          ProfileInfoSection(
            title: "Personal Information",
            items: [
              ProfileInfoItem(label: "Name", value: userName, icon: "person.fill"),
              ProfileInfoItem(label: "Email", value: userEmail, icon: "envelope.fill"),
              ProfileInfoItem(label: "Bio", value: bio, icon: "text.quote"),
            ]
          )

          ProfileInfoSection(
            title: "Statistics",
            items: [
              ProfileInfoItem(label: "Projects", value: "12", icon: "folder.fill"),
              ProfileInfoItem(label: "Documents", value: "48", icon: "doc.fill"),
              ProfileInfoItem(label: "Favorites", value: "7", icon: "heart.fill"),
            ]
          )
        }

        // Action Buttons
        VStack(spacing: 12) {
          Button(action: {
            print("Edit profile tapped")
          }) {
            Label("Edit Profile", systemImage: "pencil")
          }

          Button(action: {
            print("Change password tapped")
          }) {
            Label("Change Password", systemImage: "key.fill")
          }
        }
        .padding(.horizontal)
      }
      .padding()
    }
    .navigationTitle("Profile")
  }
}

struct ProfileInfoSection: View {
  let title: String
  let items: [ProfileInfoItem]

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      Text(title)
        .font(.headline)
        .foregroundColor(.primary)

      VStack(spacing: 8) {
        ForEach(items, id: \.label) { item in
          ProfileInfoRow(item: item)
        }
      }
      .padding()
      .cornerRadius(12)
    }
  }
}

struct ProfileInfoItem {
  let label: String
  let value: String
  let icon: String
}

struct ProfileInfoRow: View {
  let item: ProfileInfoItem

  var body: some View {
    HStack {
      Image(systemName: item.icon)
        .foregroundColor(.blue)
        .frame(width: 20)

      Text(item.label)
        .font(.subheadline)
        .foregroundColor(.secondary)

      Spacer()

      Text(item.value)
        .font(.subheadline)
        .fontWeight(.medium)
    }
  }
}

#Preview {
  NavigationView {
    ProfileView()
  }
}
