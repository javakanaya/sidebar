//
//  DocumentDetailView.swift
//  Sidebar
//
//  Created by Java Kanaya Prada on 01/09/25.
//

import SwiftUI

struct DocumentDetailView: View {
  let document: DocumentItem

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 24) {
        // Header Section
        VStack(spacing: 16) {
          Image(systemName: document.type.icon)
            .font(.system(size: 80))
            .foregroundColor(document.type.color)

          Text(document.name)
            .font(.title)
            .fontWeight(.bold)
            .multilineTextAlignment(.center)
            .padding(.horizontal)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)

        // Document Information
        VStack(alignment: .leading, spacing: 16) {
          Text("Document Information")
            .font(.headline)
            .fontWeight(.semibold)

          InfoRow(title: "File Name", value: document.name)
          InfoRow(title: "File Size", value: document.size)
          InfoRow(title: "Type", value: documentTypeString)
          InfoRow(title: "Date Modified", value: DateFormatter.localizedString(from: document.dateModified, dateStyle: .medium, timeStyle: .short))
        }
        .padding()

        // Actions Section
        VStack(alignment: .leading, spacing: 16) {
          Text("Actions")
            .font(.headline)
            .fontWeight(.semibold)

          VStack(spacing: 12) {
            ActionButton(
              title: "Open Document",
              icon: "doc.text",
              color: .blue
            ) {
              openDocument()
            }

            ActionButton(
              title: "Share Document",
              icon: "square.and.arrow.up",
              color: .green
            ) {
              shareDocument()
            }

            ActionButton(
              title: "Move to Trash",
              icon: "trash",
              color: .red
            ) {
              moveToTrash()
            }
          }
        }
        .padding()

        // Document Preview (Placeholder)
        VStack(alignment: .leading, spacing: 16) {
          Text("Preview")
            .font(.headline)
            .fontWeight(.semibold)

          RoundedRectangle(cornerRadius: 12)
            .frame(height: 200)
            .overlay(
              VStack {
                Image(systemName: "eye.slash")
                  .font(.system(size: 40))
                Text("Preview not available")
                  .font(.caption)
              }
            )
        }
        .padding()
      }
      .padding()
    }
  }

  private var documentTypeString: String {
    switch document.type {
    case .pdf:
      return "PDF Document"
    case .text:
      return "Text Document"
    case .image:
      return "Image File"
    case .spreadsheet:
      return "Spreadsheet"
    case .other:
      return "Document"
    }
  }

  private func openDocument() {
    print("Opening document: \(document.name)")
  }

  private func shareDocument() {
    print("Sharing document: \(document.name)")
  }

  private func moveToTrash() {
    print("Moving to trash: \(document.name)")
  }
}

struct InfoRow: View {
  let title: String
  let value: String

  var body: some View {
    HStack {
      Text(title)
        .font(.subheadline)
        .foregroundColor(.secondary)
        .frame(width: 100, alignment: .leading)

      Text(value)
        .font(.subheadline)
        .fontWeight(.medium)

      Spacer()
    }
  }
}

struct ActionButton: View {
  let title: String
  let icon: String
  let color: Color
  let action: () -> Void

  var body: some View {
    Button(action: action) {
      HStack {
        Image(systemName: icon)
          .font(.title3)
          .foregroundColor(color)
          .frame(width: 24)

        Text(title)
          .font(.subheadline)
          .fontWeight(.medium)

        Spacer()

        Image(systemName: "chevron.right")
          .font(.caption)
          .foregroundColor(.secondary)
      }
      .padding()
    }
    .buttonStyle(PlainButtonStyle())
  }
}

#Preview {
  NavigationView {
    DocumentDetailView(document: DocumentItem(
      id: 1,
      name: "Project Proposal.pdf",
      type: .pdf,
      size: "2.4 MB",
      dateModified: Date()
    ))
  }
}
