//
//  SidebarApp.swift
//  Sidebar
//
//  Created by Java Kanaya Prada on 01/09/25.
//

import SwiftData
import SwiftUI

@main
struct SidebarApp: App {
  var sharedModelContainer: ModelContainer = {
    let schema = Schema([
      ImageMLResultEntity.self,
      VideoMLResultEntity.self,
      VideoFrameResultEntity.self,
      DetectionResultEntity.self
    ])
    let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

    do {
      return try ModelContainer(for: schema, configurations: [modelConfiguration])
    } catch {
      fatalError("Could not create ModelContainer: \(error)")
    }
  }()

  var body: some Scene {
    WindowGroup {
      ContentView(initialSelectedItem: ViewRouter.sidebarItems.first { $0.type == .home })
    }
    .modelContainer(sharedModelContainer)
  }
}
