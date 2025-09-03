//
//  VideoMLDemoView.swift
//  Sidebar
//
//  Created by Java Kanaya Prada on 03/09/25.
//

import SwiftUI
import UniformTypeIdentifiers
import AVFoundation

struct VideoMLDemoView: View {
  @Environment(\.modelContext) private var modelContext
  @StateObject private var videoMLManager = VideoMLManager()
  @State private var selectedVideoURL: URL?
  @State private var selectedModel: ModelType = .yolo
  @State private var confidenceThreshold: Double = 0.25
  @State private var iouThreshold: Double = 0.7
  @State private var processingFrameRate: Double = 2.0
  @State private var isShowingVideoPicker = false
  @State private var expandedFrames: Set<UUID> = []
  
  enum ModelType: String, CaseIterable {
    case yolo = "YOLO11s"
    case tshirt = "T-Shirt Detection"
    
    var description: String {
      switch self {
      case .yolo:
        return "Detects 80 object classes: people, vehicles, animals, furniture, electronics, food items, etc."
      case .tshirt:
        return "Detects t-shirt colors: black, blue, grey, white"
      }
    }
    
    var icon: String {
      switch self {
      case .yolo: return "eye.fill"
      case .tshirt: return "tshirt.fill"
      }
    }
  }
  
  var body: some View {
    ScrollView {
      VStack(spacing: 24) {
        // Header
        headerSection
        
        // Model Status
        modelStatusSection
        
        // Model Selection
        modelSelectionSection
        
        // Parameters
        parametersSection
        
        // Video Selection
        videoSelectionSection
        
        // Processing Section
        if videoMLManager.isProcessing {
          processingSection
        }
        
        // Results
        if let result = videoMLManager.lastVideoResult {
          resultsSection(result)
        }
        
        Spacer(minLength: 50)
      }
      .padding(.horizontal, 24)
      .padding(.top, 20)
    }
    .navigationTitle("Video ML Demo")
    .onAppear {
      print("🎬 [VideoMLDemoView] Video ML Demo view appeared")
      print("📊 [VideoMLDemoView] Initial state - Model: \(selectedModel.rawValue), Confidence: \(confidenceThreshold), IoU: \(iouThreshold), FrameRate: \(processingFrameRate)")
      
      // Setup persistence service for auto-saving results
      videoMLManager.persistenceService = MLResultsPersistenceService(modelContext: modelContext)
    }
    .fileImporter(
      isPresented: $isShowingVideoPicker,
      allowedContentTypes: [.movie, .mpeg4Movie, .quickTimeMovie],
      allowsMultipleSelection: false
    ) { result in
      handleVideoSelection(result)
    }
  }
  
  // MARK: - Header Section
  
  private var headerSection: some View {
    VStack(spacing: 16) {
      Image(systemName: "video.and.waveform")
        .font(.system(size: 60))
        .foregroundColor(.purple)
      
      Text("Video Machine Learning Demo")
        .font(.largeTitle)
        .fontWeight(.bold)
      
      Text("Process videos with YOLO and T-Shirt detection models")
        .font(.body)
        .foregroundColor(.secondary)
        .multilineTextAlignment(.center)
    }
  }
  
  // MARK: - Model Status Section
  
  private var modelStatusSection: some View {
    GroupBox("Model Status") {
      HStack {
        Text(videoMLManager.modelsStatus)
          .font(.system(.body, design: .monospaced))
        
        Spacer()
        
        Circle()
          .fill(videoMLManager.isMLManagerReady ? .green : .orange)
          .frame(width: 12, height: 12)
      }
      
      if let error = videoMLManager.errorMessage {
        Divider()
        Text(error)
          .foregroundColor(.red)
          .font(.caption)
      }
    }
  }
  
  // MARK: - Model Selection Section
  
  private var modelSelectionSection: some View {
    GroupBox("Select Model") {
      VStack(spacing: 12) {
        Picker("Model", selection: $selectedModel) {
          ForEach(ModelType.allCases, id: \.self) { model in
            HStack {
              Text(model.rawValue)
            }
            .tag(model)
          }
        }
        .pickerStyle(.segmented)
        .onChange(of: selectedModel) { oldValue, newValue in
          print("🔄 [VideoMLDemoView] Model selection changed from \(oldValue.rawValue) to \(newValue.rawValue)")
        }
        
        // Model Description
        HStack {
          Image(systemName: selectedModel.icon)
            .foregroundColor(.purple)
          Text(selectedModel.description)
            .font(.caption)
            .foregroundColor(.secondary)
          Spacer()
        }
        .padding(.top, 8)
      }
    }
  }
  
  // MARK: - Parameters Section
  
  private var parametersSection: some View {
    GroupBox("Detection Parameters") {
      VStack(spacing: 16) {
        // Processing Frame Rate
        VStack(alignment: .leading, spacing: 4) {
          HStack {
            Text("Processing Frame Rate")
              .font(.caption)
            Spacer()
            Text("\(String(format: "%.1f", processingFrameRate)) fps")
              .font(.caption)
              .foregroundColor(.secondary)
          }
          
          Slider(value: $processingFrameRate, in: 0.5...5.0, step: 0.5)
            .onChange(of: processingFrameRate) { oldValue, newValue in
              print("🎚️ [VideoMLDemoView] Frame rate changed from \(String(format: "%.1f", oldValue)) to \(String(format: "%.1f", newValue)) fps")
            }
        }
        
        // Confidence Threshold
        VStack(alignment: .leading, spacing: 4) {
          HStack {
            Text("Confidence Threshold")
              .font(.caption)
            Spacer()
            Text(String(format: "%.2f", confidenceThreshold))
              .font(.caption)
              .foregroundColor(.secondary)
          }
          
          Slider(value: $confidenceThreshold, in: 0.1...0.9, step: 0.05)
            .onChange(of: confidenceThreshold) { oldValue, newValue in
              print("🎚️ [VideoMLDemoView] Confidence threshold changed from \(String(format: "%.2f", oldValue)) to \(String(format: "%.2f", newValue))")
            }
        }
        
        // IoU Threshold
        VStack(alignment: .leading, spacing: 4) {
          HStack {
            Text("IoU Threshold")
              .font(.caption)
            Spacer()
            Text(String(format: "%.2f", iouThreshold))
              .font(.caption)
              .foregroundColor(.secondary)
          }
          
          Slider(value: $iouThreshold, in: 0.1...0.9, step: 0.05)
            .onChange(of: iouThreshold) { oldValue, newValue in
              print("🎚️ [VideoMLDemoView] IoU threshold changed from \(String(format: "%.2f", oldValue)) to \(String(format: "%.2f", newValue))")
            }
        }
      }
    }
  }
  
  // MARK: - Video Selection Section
  
  private var videoSelectionSection: some View {
    GroupBox("Video Input") {
      VStack(spacing: 16) {
        if let videoURL = selectedVideoURL {
          // Show selected video info
          VStack(spacing: 12) {
            HStack {
              Image(systemName: "video")
                .font(.title2)
                .foregroundColor(.purple)
              
              VStack(alignment: .leading, spacing: 4) {
                Text(videoURL.lastPathComponent)
                  .font(.headline)
                  .lineLimit(1)
                
                if let videoInfo = getVideoInfo(url: videoURL) {
                  Text("Duration: \(formatDuration(videoInfo.duration))")
                    .font(.caption)
                    .foregroundColor(.secondary)
                  Text("Size: \(formatFileSize(videoInfo.fileSize))")
                    .font(.caption)
                    .foregroundColor(.secondary)
                }
              }
              
              Spacer()
            }
            .padding()
            .background(Color.purple.opacity(0.1))
            .cornerRadius(8)
            
            HStack {
              Button("Choose Different Video") {
                print("🎬 [VideoMLDemoView] User clicked 'Choose Different Video'")
                isShowingVideoPicker = true
              }
              .buttonStyle(.bordered)
              
              Spacer()
              
              Button("Start Processing") {
                print("🚀 [VideoMLDemoView] User clicked 'Start Processing'")
                startVideoProcessing()
              }
              .buttonStyle(.borderedProminent)
              .disabled(videoMLManager.isProcessing || !videoMLManager.isMLManagerReady)
            }
          }
        } else {
          // Video picker placeholder
          Button(action: { 
            print("🎬 [VideoMLDemoView] User clicked video selection placeholder")
            isShowingVideoPicker = true 
          }) {
            VStack(spacing: 12) {
              Image(systemName: "video.badge.plus")
                .font(.system(size: 40))
                .foregroundColor(.purple)
              
              Text("Select a Video")
                .font(.headline)
              
              Text("Choose a video file to run ML detection")
                .font(.caption)
                .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(40)
            .background(Color.purple.opacity(0.1))
            .cornerRadius(12)
          }
          .buttonStyle(.plain)
        }
      }
    }
  }
  
  // MARK: - Processing Section
  
  private var processingSection: some View {
    GroupBox("Processing Video") {
      VStack(spacing: 16) {
        // Progress Bar
        VStack(alignment: .leading, spacing: 8) {
          HStack {
            Text("Progress")
              .font(.headline)
            
            Spacer()
            
            Text("\(Int(videoMLManager.processingProgress * 100))%")
              .font(.subheadline)
              .foregroundColor(.secondary)
          }
          
          ProgressView(value: videoMLManager.processingProgress, total: 1.0)
            .progressViewStyle(LinearProgressViewStyle(tint: .purple))
        }
        
        // Status Text
        if !videoMLManager.currentProcessingStatus.isEmpty {
          HStack {
            ProgressView()
              .scaleEffect(0.8)
            
            Text(videoMLManager.currentProcessingStatus)
              .font(.caption)
              .foregroundColor(.secondary)
            
            Spacer()
          }
        }
        
        // Cancel Button
        Button("Cancel Processing") {
          print("🛑 [VideoMLDemoView] User clicked 'Cancel Processing'")
          videoMLManager.cancelProcessing()
        }
        .buttonStyle(.bordered)
        .foregroundColor(.red)
      }
    }
  }
  
  // MARK: - Results Section
  
  private func resultsSection(_ result: VideoMLResult) -> some View {
    GroupBox("Video Processing Results") {
      VStack(alignment: .leading, spacing: 20) {
        // Summary Statistics
        summarySection(result)
        
        // Timeline of Detections
        timelineSection(result)
      }
    }
  }
  
  private func summarySection(_ result: VideoMLResult) -> some View {
    VStack(alignment: .leading, spacing: 16) {
      Text("Summary")
        .font(.headline)
      
      LazyVGrid(columns: [
        GridItem(.flexible()),
        GridItem(.flexible())
      ], spacing: 12) {
        StatCard(title: "Total Detections", value: "\(result.totalDetections)")
        StatCard(title: "Frames Processed", value: "\(result.totalFramesProcessed)")
        StatCard(title: "Video Duration", value: formatDuration(result.totalDuration))
        StatCard(title: "Processing Time", value: "\(String(format: "%.1f", result.totalProcessingTime))s")
        StatCard(title: "Avg. per Frame", value: "\(String(format: "%.0f", result.averageProcessingTime * 1000))ms")
        StatCard(title: "Detections/sec", value: String(format: "%.1f", result.detectionsPerSecond))
      }
    }
  }
  
  private func timelineSection(_ result: VideoMLResult) -> some View {
    VStack(alignment: .leading, spacing: 12) {
      HStack {
        Text("Detection Timeline")
          .font(.headline)
        
        Spacer()
        
        Text("\(result.processedFrames.filter { !$0.detections.isEmpty }.count) frames with detections")
          .font(.caption)
          .foregroundColor(.secondary)
      }
      
      if result.processedFrames.filter({ !$0.detections.isEmpty }).isEmpty {
        HStack {
          Image(systemName: "exclamationmark.circle")
            .foregroundColor(.orange)
          Text("No objects detected in any frame. Try lowering the confidence threshold.")
            .font(.caption)
            .foregroundColor(.secondary)
        }
        .padding()
        .background(Color.orange.opacity(0.1))
        .cornerRadius(8)
      } else {
        LazyVStack(spacing: 8) {
          ForEach(result.processedFrames.filter { !$0.detections.isEmpty }) { frame in
            frameCard(frame: frame)
          }
        }
      }
    }
  }
  
  private func frameCard(frame: VideoDetectionFrame) -> some View {
    VStack(alignment: .leading, spacing: 8) {
      // Frame Header
      HStack {
        VStack(alignment: .leading, spacing: 2) {
          Text("Frame \(frame.frameNumber)")
            .font(.subheadline)
            .fontWeight(.medium)
          
          Text("@ \(formatTimestamp(frame.timestamp))")
            .font(.caption)
            .foregroundColor(.secondary)
        }
        
        Spacer()
        
        Text("\(frame.detections.count) detections")
          .font(.caption)
          .padding(.horizontal, 8)
          .padding(.vertical, 2)
          .background(Color.blue.opacity(0.1))
          .cornerRadius(4)
        
        Button(action: {
          if expandedFrames.contains(frame.id) {
            expandedFrames.remove(frame.id)
          } else {
            expandedFrames.insert(frame.id)
          }
        }) {
          Image(systemName: expandedFrames.contains(frame.id) ? "chevron.up" : "chevron.down")
            .font(.caption)
        }
        .buttonStyle(.plain)
      }
      
      // Expandable Detection Details
      if expandedFrames.contains(frame.id) {
        Divider()
        
        LazyVStack(spacing: 4) {
          ForEach(frame.detections.prefix(20)) { detection in // Show top 20
            HStack {
              Circle()
                .fill(detection.color)
                .frame(width: 8, height: 8)
              
              Text(detection.label.capitalized)
                .font(.caption)
                .fontWeight(.medium)
              
              Spacer()
              
              Text("\(Int(detection.confidence * 100))%")
                .font(.caption2)
                .foregroundColor(.secondary)
                .padding(.horizontal, 4)
                .padding(.vertical, 1)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(3)
            }
          }
        }
        .padding(.top, 4)
        
        if frame.detections.count > 20 {
          Text("... and \(frame.detections.count - 20) more detections")
            .font(.caption2)
            .foregroundColor(.secondary)
            .padding(.top, 2)
        }
      }
    }
    .padding()
    .background(Color.gray.opacity(0.05))
    .cornerRadius(8)
  }
  
  // MARK: - Helper Views
  
  private struct StatCard: View {
    let title: String
    let value: String
    
    var body: some View {
      VStack(alignment: .leading, spacing: 4) {
        Text(title)
          .font(.caption)
          .foregroundColor(.secondary)
        
        Text(value)
          .font(.headline)
          .fontWeight(.semibold)
      }
      .padding()
      .frame(maxWidth: .infinity, alignment: .leading)
      .background(Color.gray.opacity(0.05))
      .cornerRadius(8)
    }
  }
  
  // MARK: - Helper Methods
  
  private func handleVideoSelection(_ result: Result<[URL], Error>) {
    print("🎬 [VideoMLDemoView] Handling video selection result...")
    switch result {
    case .success(let urls):
      if let url = urls.first {
        print("✅ [VideoMLDemoView] Video selected: \(url.lastPathComponent)")
        
        // Store the URL directly - we'll access security-scoped resource when processing
        selectedVideoURL = url
        
        // Just verify it's a video file without accessing the resource yet
        Task {
          // Create a security-scoped access for verification only
          guard url.startAccessingSecurityScopedResource() else {
            await MainActor.run {
              print("❌ [VideoMLDemoView] Failed to access security-scoped resource during verification")
              videoMLManager.errorMessage = "Failed to access selected video file"
              selectedVideoURL = nil
            }
            return
          }
          
          defer {
            url.stopAccessingSecurityScopedResource()
            print("🔓 [VideoMLDemoView] Released security-scoped resource access after verification")
          }
          
          let asset = AVAsset(url: url)
          do {
            let isReadable = try await asset.load(.isReadable)
            if isReadable {
              print("✅ [VideoMLDemoView] Video verification successful")
            } else {
              await MainActor.run {
                videoMLManager.errorMessage = "Selected file is not a readable video"
                selectedVideoURL = nil
              }
            }
          } catch {
            await MainActor.run {
              print("❌ [VideoMLDemoView] Video verification failed: \(error)")
              videoMLManager.errorMessage = "Failed to verify video: \(error.localizedDescription)"
              selectedVideoURL = nil
            }
          }
        }
      }
    case .failure(let error):
      print("❌ [VideoMLDemoView] Video selection failed: \(error)")
      videoMLManager.errorMessage = "Failed to select video: \(error.localizedDescription)"
    }
  }
  
  private func startVideoProcessing() {
    guard let videoURL = selectedVideoURL else { return }
    
    print("🚀 [VideoMLDemoView] Starting video processing")
    print("⚙️ [VideoMLDemoView] Parameters: model=\(selectedModel.rawValue), confidence=\(confidenceThreshold), iou=\(iouThreshold), frameRate=\(processingFrameRate)")
    
    Task {
      await videoMLManager.processVideo(
        url: videoURL,
        model: selectedModel,
        confidenceThreshold: confidenceThreshold,
        iouThreshold: iouThreshold,
        frameRate: processingFrameRate
      )
    }
  }
  
  private func getVideoInfo(url: URL) -> (duration: TimeInterval, fileSize: Int64)? {
    // Access security-scoped resource for getting video info
    guard url.startAccessingSecurityScopedResource() else {
      print("❌ [VideoMLDemoView] Failed to access security-scoped resource for video info")
      return nil
    }
    
    defer {
      url.stopAccessingSecurityScopedResource()
    }
    
    do {
      let asset = AVAsset(url: url)
      let duration = asset.duration
      let durationSeconds = CMTimeGetSeconds(duration)
      
      let fileAttributes = try FileManager.default.attributesOfItem(atPath: url.path)
      let fileSize = fileAttributes[.size] as? Int64 ?? 0
      
      return (duration: durationSeconds, fileSize: fileSize)
    } catch {
      print("❌ [VideoMLDemoView] Failed to get video info: \(error)")
      return nil
    }
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
  
  private func formatFileSize(_ bytes: Int64) -> String {
    let formatter = ByteCountFormatter()
    formatter.allowedUnits = [.useMB, .useGB]
    formatter.countStyle = .file
    return formatter.string(fromByteCount: bytes)
  }
}

#Preview {
  VideoMLDemoView()
}
