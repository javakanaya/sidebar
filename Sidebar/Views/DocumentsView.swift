//
//  DocumentsView.swift
//  Sidebar
//
//  Created by Java Kanaya Prada on 01/09/25.
//

import SwiftUI

struct DocumentsView: View {
  @State private var documents = [
    DocumentItem(id: 1, name: "Project Proposal.pdf", type: .pdf, size: "2.4 MB", dateModified: Date()),
    DocumentItem(id: 2, name: "Meeting Notes.txt", type: .text, size: "18 KB", dateModified: Date().addingTimeInterval(-86400)),
    DocumentItem(id: 3, name: "Design Mockups.sketch", type: .image, size: "15.2 MB", dateModified: Date().addingTimeInterval(-172_800)),
    DocumentItem(id: 4, name: "Budget Spreadsheet.xlsx", type: .spreadsheet, size: "456 KB", dateModified: Date().addingTimeInterval(-259_200)),
  ]

  @State private var searchText = ""

  var filteredDocuments: [DocumentItem] {
    if searchText.isEmpty {
      return documents
    } else {
      return documents.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }
  }

  var body: some View {
    NavigationStack {
      VStack(spacing: 0) {
        // Header
        VStack(spacing: 16) {
          Image(systemName: "doc.fill")
            .font(.system(size: 60))
            .foregroundColor(.blue)

          Text("Documents")
            .font(.largeTitle)
            .fontWeight(.bold)

          Text("\(documents.count) documents")
            .font(.subheadline)
            .foregroundColor(.secondary)
        }
        .padding(.bottom, 24)

        // Search Bar
        HStack {
          Image(systemName: "magnifyingglass")
            .foregroundColor(.secondary)

          TextField("Search documents...", text: $searchText)
            .textFieldStyle(RoundedBorderTextFieldStyle())
        }
        .padding(.horizontal)
        .padding(.bottom, 16)

        // Documents List
        ForEach(filteredDocuments) { document in
          NavigationLink(value: document) {
            DocumentRow(document: document)
          }
          .buttonStyle(PlainButtonStyle())
        }
      }
      .padding(.top)
      .navigationTitle("Documents")
      .navigationDestination(for: DocumentItem.self) { document in
        DocumentDetailView(document: document)
      }
      .toolbar {
        ToolbarItem(placement: .primaryAction) {
          Button(action: addDocument) {
            Label("Add Document", systemImage: "plus")
          }
        }
      }
    }
  }

  private func deleteDocument(_ document: DocumentItem) {
    documents.removeAll { $0.id == document.id }
  }

  private func shareDocument(_ document: DocumentItem) {
    print("Sharing document: \(document.name)")
  }

  private func addDocument() {
    print("Add document tapped")
  }
}

struct DocumentItem: Identifiable, Hashable {
  let id: Int
  let name: String
  let type: DocumentType
  let size: String
  let dateModified: Date
}

enum DocumentType: Hashable {
  case pdf, text, image, spreadsheet, other

  var icon: String {
    switch self {
    case .pdf:
      return "doc.fill"
    case .text:
      return "doc.text.fill"
    case .image:
      return "photo.fill"
    case .spreadsheet:
      return "tablecells.fill"
    case .other:
      return "doc.fill"
    }
  }

  var color: Color {
    switch self {
    case .pdf:
      return .red
    case .text:
      return .blue
    case .image:
      return .green
    case .spreadsheet:
      return .orange
    case .other:
      return .gray
    }
  }
}

struct DocumentRow: View {
  let document: DocumentItem

  var body: some View {
    HStack(spacing: 12) {
      Image(systemName: document.type.icon)
        .font(.title2)
        .foregroundColor(document.type.color)
        .frame(width: 30)

      VStack(alignment: .leading, spacing: 4) {
        Text(document.name)
          .font(.headline)
          .lineLimit(1)

        HStack {
          Text(document.size)
            .font(.caption)
            .foregroundColor(.secondary)

          Text("•")
            .font(.caption)
            .foregroundColor(.secondary)

          Text(document.dateModified, style: .date)
            .font(.caption)
            .foregroundColor(.secondary)
        }
      }

      Spacer()
    }
    .padding(.vertical, 8)
  }
}

#Preview {
  NavigationView {
    DocumentsView()
  }
}
