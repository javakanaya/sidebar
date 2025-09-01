//
//  FavoritesView.swift
//  Sidebar
//
//  Created by Java Kanaya Prada on 01/09/25.
//

import SwiftUI

struct FavoritesView: View {
  @State private var favoriteItems = [
    FavoriteItem(id: 1, title: "Important Project", type: .project, isFavorited: true),
    FavoriteItem(id: 2, title: "Team Meeting Notes", type: .document, isFavorited: true),
    FavoriteItem(id: 3, title: "Design Resources", type: .folder, isFavorited: true),
    FavoriteItem(id: 4, title: "Quick Reference Guide", type: .document, isFavorited: true),
    FavoriteItem(id: 5, title: "Client Feedback", type: .project, isFavorited: true),
  ]

  var body: some View {
    VStack(spacing: 0) {
      // Header
      VStack(spacing: 16) {
        Image(systemName: "heart.fill")
          .font(.system(size: 60))
          .foregroundColor(.red)

        Text("Favorites")
          .font(.largeTitle)
          .fontWeight(.bold)

        Text("\(favoriteItems.count) favorite items")
          .font(.subheadline)
          .foregroundColor(.secondary)
      }
      .padding(.bottom, 24)

      if favoriteItems.isEmpty {
        // Empty State
        VStack(spacing: 16) {
          Image(systemName: "heart")
            .font(.system(size: 40))
            .foregroundColor(.secondary)

          Text("No favorites yet")
            .font(.headline)
            .foregroundColor(.secondary)

          Text("Items you mark as favorites will appear here")
            .font(.subheadline)
            .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
      } else {
        // Favorites List
        List {
          ForEach(favoriteItems) { item in
            FavoriteRow(item: item) {
              toggleFavorite(item)
            }
          }
          .onDelete(perform: deleteFavorites)
        }
        .listStyle(PlainListStyle())
      }
    }
    .padding(.top)
    .navigationTitle("Favorites")
  }

  private func toggleFavorite(_ item: FavoriteItem) {
    if let index = favoriteItems.firstIndex(where: { $0.id == item.id }) {
      favoriteItems[index].isFavorited.toggle()
      if !favoriteItems[index].isFavorited {
        favoriteItems.remove(at: index)
      }
    }
  }

  private func deleteFavorites(at offsets: IndexSet) {
    favoriteItems.remove(atOffsets: offsets)
  }
}

struct FavoriteItem: Identifiable {
  let id: Int
  let title: String
  let type: FavoriteType
  var isFavorited: Bool
}

enum FavoriteType {
  case project, document, folder, other

  var icon: String {
    switch self {
    case .project:
      return "folder.badge.gear"
    case .document:
      return "doc.fill"
    case .folder:
      return "folder.fill"
    case .other:
      return "star.fill"
    }
  }

  var color: Color {
    switch self {
    case .project:
      return .blue
    case .document:
      return .green
    case .folder:
      return .orange
    case .other:
      return .purple
    }
  }

  var typeName: String {
    switch self {
    case .project:
      return "Project"
    case .document:
      return "Document"
    case .folder:
      return "Folder"
    case .other:
      return "Item"
    }
  }
}

struct FavoriteRow: View {
  let item: FavoriteItem
  let onToggleFavorite: () -> Void

  var body: some View {
    HStack(spacing: 12) {
      Image(systemName: item.type.icon)
        .font(.title2)
        .foregroundColor(item.type.color)
        .frame(width: 30)

      VStack(alignment: .leading, spacing: 4) {
        Text(item.title)
          .font(.headline)
          .lineLimit(2)

        Text(item.type.typeName)
          .font(.caption)
          .foregroundColor(.secondary)
      }

      Spacer()

      Button(action: onToggleFavorite) {
        Image(systemName: item.isFavorited ? "heart.fill" : "heart")
          .font(.title3)
          .foregroundColor(item.isFavorited ? .red : .secondary)
      }
      .buttonStyle(PlainButtonStyle())
    }
    .padding(.vertical, 8)
    .contentShape(Rectangle())
  }
}

#Preview {
  NavigationView {
    FavoritesView()
  }
}
