//
//  RecentResultsView.swift
//  Sidebar
//
//  Created by Java Kanaya Prada on 03/09/25.
//

import SwiftUI
import SwiftData

struct RecentResultsView: View {
  @Environment(\.modelContext) private var modelContext
  @State private var persistenceService: MLResultsPersistenceService?
  @State private var selectedTab: TabType = .images
  @State private var searchText = ""
  @State private var imageResults: [ImageMLResultEntity] = []
  @State private var videoResults: [VideoMLResultEntity] = []
  @State private var isLoading = true
  
  enum TabType: String, CaseIterable {
    case images = "Images"
    case videos = "Videos"
    
    var icon: String {
      switch self {
      case .images: return "photo.stack"
      case .videos: return "video.stack"
      }
    }
  }
  
  init() {
    // No need to initialize persistence service here
    // It will be created in onAppear when we have modelContext
  }
  
  var body: some View {
    NavigationView {
      VStack(spacing: 0) {
        // Header with tabs
        headerSection
        
        // Search bar
        searchSection
        
        // Content based on selected tab
        if isLoading {
          loadingSection
        } else {
          contentSection
        }
      }
      .navigationTitle("Recent Results")
      .onAppear {
        setupPersistenceService()
        loadResults()
      }
      .onChange(of: selectedTab) { _, _ in
        loadResults()
      }
      .onChange(of: searchText) { _, _ in
        searchResults()
      }
    }
  }
  
  // MARK: - Header Section
  
  private var headerSection: some View {
    VStack(spacing: 16) {
      // Icon and title
      HStack(spacing: 12) {
        Image(systemName: "clock.arrow.circlepath")
          .font(.system(size: 50))
          .foregroundColor(.blue)
        
        VStack(alignment: .leading, spacing: 4) {
          Text("Recent ML Results")
            .font(.largeTitle)
            .fontWeight(.bold)
          
          Text("View your saved image and video processing results")
            .font(.body)
            .foregroundColor(.secondary)
        }
        
        Spacer()
      }
      
      // Tab selector
      Picker("Result Type", selection: $selectedTab) {
        ForEach(TabType.allCases, id: \.self) { tab in
          HStack {
            Text(tab.rawValue)
          }
          .tag(tab)
        }
      }
      .pickerStyle(.segmented)
    }
    .padding(.horizontal, 24)
    .padding(.top, 20)
  }
  
  // MARK: - Search Section
  
  private var searchSection: some View {
    HStack {
      Image(systemName: "magnifyingglass")
        .foregroundColor(.secondary)
      
      TextField("Search results...", text: $searchText)
        .textFieldStyle(.plain)
      
      if !searchText.isEmpty {
        Button(action: { searchText = "" }) {
          Image(systemName: "xmark.circle.fill")
            .foregroundColor(.secondary)
        }
        .buttonStyle(.plain)
      }
    }
    .padding(.horizontal, 12)
    .padding(.vertical, 8)
    .background(Color.gray.opacity(0.1))
    .cornerRadius(8)
    .padding(.horizontal, 24)
    .padding(.top, 16)
  }
  
  // MARK: - Loading Section
  
  private var loadingSection: some View {
    VStack(spacing: 12) {
      ProgressView()
        .scaleEffect(1.2)
      
      Text("Loading results...")
        .font(.headline)
        .foregroundColor(.secondary)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
  }
  
  // MARK: - Content Section
  
  private var contentSection: some View {
    ScrollView {
      LazyVStack(spacing: 16) {
        switch selectedTab {
        case .images:
          imageResultsSection
        case .videos:
          videoResultsSection
        }
      }
      .padding(.horizontal, 24)
      .padding(.top, 16)
    }
  }
  
  // MARK: - Image Results Section
  
  private var imageResultsSection: some View {
    Group {
      if imageResults.isEmpty {
        emptyStateView(type: .images)
      } else {
        ForEach(imageResults, id: \.id) { result in
          ImageResultCard(
            result: result,
            onDelete: { deleteImageResult(result) }
          )
        }
      }
    }
  }
  
  // MARK: - Video Results Section
  
  private var videoResultsSection: some View {
    Group {
      if videoResults.isEmpty {
        emptyStateView(type: .videos)
      } else {
        ForEach(videoResults, id: \.id) { result in
          VideoResultCard(
            result: result,
            onDelete: { deleteVideoResult(result) }
          )
        }
      }
    }
  }
  
  // MARK: - Empty State
  
  private func emptyStateView(type: TabType) -> some View {
    VStack(spacing: 20) {
      Image(systemName: type == .images ? "photo.stack" : "video.stack")
        .font(.system(size: 60))
        .foregroundColor(.gray)
      
      Text("No \(type.rawValue.lowercased()) results yet")
        .font(.headline)
        .foregroundColor(.secondary)
      
      Text("Process some \(type == .images ? "images" : "videos") with ML detection to see results here")
        .font(.body)
        .foregroundColor(.secondary)
        .multilineTextAlignment(.center)
    }
    .frame(maxWidth: .infinity)
    .padding(.top, 100)
  }
  
  // MARK: - Helper Methods
  
  private func setupPersistenceService() {
    if persistenceService == nil {
      persistenceService = MLResultsPersistenceService(modelContext: modelContext)
    }
  }
  
  private func loadResults() {
    guard let persistenceService = persistenceService else { return }
    
    isLoading = true
    
    Task {
      await MainActor.run {
        switch selectedTab {
        case .images:
          imageResults = persistenceService.fetchImageResults()
        case .videos:
          videoResults = persistenceService.fetchVideoResults()
        }
        isLoading = false
      }
    }
  }
  
  private func searchResults() {
    guard let persistenceService = persistenceService else { return }
    
    if searchText.isEmpty {
      loadResults()
      return
    }
    
    Task {
      await MainActor.run {
        switch selectedTab {
        case .images:
          imageResults = persistenceService.searchImageResults(query: searchText)
        case .videos:
          videoResults = persistenceService.searchVideoResults(query: searchText)
        }
      }
    }
  }
  
  private func deleteImageResult(_ result: ImageMLResultEntity) {
    guard let persistenceService = persistenceService else { return }
    persistenceService.deleteImageResult(result)
    loadResults()
  }
  
  private func deleteVideoResult(_ result: VideoMLResultEntity) {
    guard let persistenceService = persistenceService else { return }
    persistenceService.deleteVideoResult(result)
    loadResults()
  }
}

// MARK: - Image Result Card

struct ImageResultCard: View {
  let result: ImageMLResultEntity
  let onDelete: () -> Void
  @State private var isExpanded = false
  
  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      // Header
      HStack {
        VStack(alignment: .leading, spacing: 4) {
          Text(result.imageName ?? "Unknown Image")
            .font(.headline)
            .fontWeight(.medium)
          
          Text(result.processedAt, style: .time)
            .font(.caption)
            .foregroundColor(.secondary)
        }
        
        Spacer()
        
        HStack(spacing: 12) {
          Text("\(result.totalDetections) detections")
            .font(.caption)
            .padding(.horizontal, 8)
            .padding(.vertical, 2)
            .background(Color.blue.opacity(0.1))
            .cornerRadius(4)
          
          Button(action: { onDelete() }) {
            Image(systemName: "trash")
              .foregroundColor(.red)
          }
          .buttonStyle(.plain)
          
          Button(action: { isExpanded.toggle() }) {
            Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
          }
          .buttonStyle(.plain)
        }
      }
      
      // Summary
      HStack {
        Label(result.modelUsed, systemImage: "brain.head.profile")
          .font(.caption)
        
        Spacer()
        
        Text("Processing: \(Int(result.processingTime * 1000))ms")
          .font(.caption)
          .foregroundColor(.secondary)
      }
      
      // Expandable details
      if isExpanded {
        Divider()
        
        VStack(alignment: .leading, spacing: 8) {
          Text("Detection Details")
            .font(.subheadline)
            .fontWeight(.medium)
          
          LazyVStack(spacing: 4) {
            ForEach(result.detections.prefix(10), id: \.id) { detection in
              HStack {
                Circle()
                  .fill(detection.colorType.swiftUIColor)
                  .frame(width: 8, height: 8)
                
                Text(detection.label.capitalized)
                  .font(.caption)
                
                Spacer()
                
                Text("\(Int(detection.confidence * 100))%")
                  .font(.caption2)
                  .foregroundColor(.secondary)
              }
            }
          }
          
          if result.detections.count > 10 {
            Text("... and \(result.detections.count - 10) more detections")
              .font(.caption2)
              .foregroundColor(.secondary)
          }
        }
      }
    }
    .padding()
    .background(Color.gray.opacity(0.05))
    .cornerRadius(12)
  }
}

// MARK: - Video Result Card

struct VideoResultCard: View {
  let result: VideoMLResultEntity
  let onDelete: () -> Void
  @State private var isExpanded = false
  
  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      // Header
      HStack {
        VStack(alignment: .leading, spacing: 4) {
          Text(result.videoName)
            .font(.headline)
            .fontWeight(.medium)
          
          Text(result.processedAt, style: .time)
            .font(.caption)
            .foregroundColor(.secondary)
        }
        
        Spacer()
        
        HStack(spacing: 12) {
          Text("\(result.totalDetections) detections")
            .font(.caption)
            .padding(.horizontal, 8)
            .padding(.vertical, 2)
            .background(Color.purple.opacity(0.1))
            .cornerRadius(4)
          
          Button(action: { onDelete() }) {
            Image(systemName: "trash")
              .foregroundColor(.red)
          }
          .buttonStyle(.plain)
          
          Button(action: { isExpanded.toggle() }) {
            Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
          }
          .buttonStyle(.plain)
        }
      }
      
      // Summary
      VStack(spacing: 4) {
        HStack {
          Label(result.modelUsed, systemImage: "video.and.waveform")
            .font(.caption)
          
          Spacer()
          
          Text("Duration: \(formatDuration(result.totalDuration))")
            .font(.caption)
            .foregroundColor(.secondary)
        }
        
        HStack {
          Text("Frames: \(result.processedFrames.count)")
            .font(.caption)
            .foregroundColor(.secondary)
          
          Spacer()
          
          Text("Processing: \(formatDuration(result.totalProcessingTime))")
            .font(.caption)
            .foregroundColor(.secondary)
        }
      }
      
      // Expandable details
      if isExpanded {
        Divider()
        
        VStack(alignment: .leading, spacing: 8) {
          Text("Frame Timeline")
            .font(.subheadline)
            .fontWeight(.medium)
          
          LazyVStack(spacing: 6) {
            ForEach(result.processedFrames.filter { !$0.detections.isEmpty }.prefix(5), id: \.id) { frame in
              HStack {
                Text("Frame \(frame.frameNumber)")
                  .font(.caption)
                  .fontWeight(.medium)
                
                Text("@ \(formatTimestamp(frame.timestamp))")
                  .font(.caption2)
                  .foregroundColor(.secondary)
                
                Spacer()
                
                Text("\(frame.detections.count) detections")
                  .font(.caption2)
                  .padding(.horizontal, 4)
                  .padding(.vertical, 1)
                  .background(Color.gray.opacity(0.1))
                  .cornerRadius(3)
              }
            }
          }
          
          let framesWithDetections = result.processedFrames.filter { !$0.detections.isEmpty }
          if framesWithDetections.count > 5 {
            Text("... and \(framesWithDetections.count - 5) more frames with detections")
              .font(.caption2)
              .foregroundColor(.secondary)
          }
        }
      }
    }
    .padding()
    .background(Color.gray.opacity(0.05))
    .cornerRadius(12)
  }
  
  private func formatDuration(_ seconds: TimeInterval) -> String {
    let minutes = Int(seconds) / 60
    let remainingSeconds = Int(seconds) % 60
    return String(format: "%d:%02d", minutes, remainingSeconds)
  }
  
  private func formatTimestamp(_ seconds: TimeInterval) -> String {
    let minutes = Int(seconds) / 60
    let remainingSeconds = seconds.truncatingRemainder(dividingBy: 60)
    return String(format: "%d:%05.2f", minutes, remainingSeconds)
  }
}

#Preview {
  RecentResultsView()
}
