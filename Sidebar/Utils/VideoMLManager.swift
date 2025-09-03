//
//  VideoMLManager.swift
//  Sidebar
//
//  Created by Java Kanaya Prada on 03/09/25.
//

import CoreML
import Vision
import SwiftUI
import AVFoundation

// MARK: - Video Detection Result Models

struct VideoDetectionFrame: Identifiable {
  let id = UUID()
  let timestamp: TimeInterval
  let frameNumber: Int
  let detections: [DetectionResult]
  let processingTime: TimeInterval
}

struct VideoMLResult {
  let videoURL: URL
  let totalDuration: TimeInterval
  let processedFrames: [VideoDetectionFrame]
  let totalProcessingTime: TimeInterval
  let modelUsed: String
  let frameRate: Double // frames processed per second
  let totalFramesProcessed: Int
  
  var averageProcessingTime: TimeInterval {
    guard !processedFrames.isEmpty else { return 0 }
    return processedFrames.map { $0.processingTime }.reduce(0, +) / Double(processedFrames.count)
  }
  
  var totalDetections: Int {
    processedFrames.reduce(0) { $0 + $1.detections.count }
  }
  
  var detectionsPerSecond: Double {
    guard totalDuration > 0 else { return 0 }
    return Double(totalDetections) / totalDuration
  }
}

// MARK: - Video ML Manager

@MainActor
class VideoMLManager: ObservableObject {
  @Published var isProcessing = false
  @Published var processingProgress: Double = 0.0
  @Published var errorMessage: String?
  @Published var lastVideoResult: VideoMLResult?
  @Published var currentProcessingStatus: String = ""
  
  // Dependencies
  private let mlManager = MLManager()
  
  // Processing configuration
  private var processingFrameRate: Double = 2.0 // Process 2 frames per second
  private var isCancelled = false
  
  // MARK: - Public Interface
  
  func processVideo(
    url: URL,
    model: VideoMLDemoView.ModelType,
    confidenceThreshold: Double = 0.25,
    iouThreshold: Double = 0.7,
    frameRate: Double = 2.0
  ) async {
    print("🎬 [VideoMLManager] Starting video processing...")
    print("📹 [VideoMLManager] Video URL: \(url.lastPathComponent)")
    print("🤖 [VideoMLManager] Model: \(model.rawValue)")
    print("⚙️ [VideoMLManager] Config: confidence=\(confidenceThreshold), iou=\(iouThreshold), frameRate=\(frameRate)fps")
    
    // Access security-scoped resource for the entire processing duration
    guard url.startAccessingSecurityScopedResource() else {
      print("❌ [VideoMLManager] Failed to access security-scoped resource")
      errorMessage = "Failed to access video file. Please try selecting the video again."
      return
    }
    
    defer {
      url.stopAccessingSecurityScopedResource()
      print("🔓 [VideoMLManager] Released security-scoped resource access")
    }
    
    isProcessing = true
    processingProgress = 0.0
    errorMessage = nil
    isCancelled = false
    processingFrameRate = frameRate
    currentProcessingStatus = "Initializing video processing..."
    
    defer {
      isProcessing = false
      currentProcessingStatus = ""
      print("🏁 [VideoMLManager] Video processing completed")
    }
    
    do {
      // Load video asset
      let asset = AVAsset(url: url)
      let duration = try await asset.load(.duration)
      let durationSeconds = CMTimeGetSeconds(duration)
      
      print("📊 [VideoMLManager] Video duration: \(String(format: "%.2f", durationSeconds))s")
      currentProcessingStatus = "Video loaded successfully"
      
      // Calculate frame extraction parameters
      let frameInterval = 1.0 / frameRate
      let totalFramesToProcess = Int(durationSeconds * frameRate)
      
      print("📈 [VideoMLManager] Will process \(totalFramesToProcess) frames (1 every \(String(format: "%.2f", frameInterval))s)")
      
      // Extract and process frames
      let frames = try await extractAndProcessFrames(
        asset: asset,
        duration: durationSeconds,
        frameInterval: frameInterval,
        totalFrames: totalFramesToProcess,
        model: model,
        confidenceThreshold: confidenceThreshold,
        iouThreshold: iouThreshold
      )
      
      // Calculate total processing time
      let totalProcessingTime = frames.reduce(0) { $0 + $1.processingTime }
      
      // Create result
      let result = VideoMLResult(
        videoURL: url,
        totalDuration: durationSeconds,
        processedFrames: frames,
        totalProcessingTime: totalProcessingTime,
        modelUsed: model.rawValue,
        frameRate: frameRate,
        totalFramesProcessed: frames.count
      )
      
      lastVideoResult = result
      currentProcessingStatus = "Processing completed successfully!"
      
      print("✅ [VideoMLManager] Processing complete!")
      print("📊 [VideoMLManager] Results: \(frames.count) frames, \(result.totalDetections) total detections")
      print("⏱️ [VideoMLManager] Total processing time: \(String(format: "%.2f", totalProcessingTime))s")
      
    } catch {
      print("❌ [VideoMLManager] Video processing failed: \(error)")
      errorMessage = "Video processing failed: \(error.localizedDescription)"
      currentProcessingStatus = "Processing failed"
    }
  }
  
  func cancelProcessing() {
    print("🛑 [VideoMLManager] Processing cancellation requested")
    isCancelled = true
    currentProcessingStatus = "Cancelling..."
  }
  
  // MARK: - Private Implementation
  
  private func extractAndProcessFrames(
    asset: AVAsset,
    duration: TimeInterval,
    frameInterval: TimeInterval,
    totalFrames: Int,
    model: VideoMLDemoView.ModelType,
    confidenceThreshold: Double,
    iouThreshold: Double
  ) async throws -> [VideoDetectionFrame] {
    print("🎞️ [VideoMLManager] Starting frame extraction and processing...")
    
    let imageGenerator = AVAssetImageGenerator(asset: asset)
    imageGenerator.appliesPreferredTrackTransform = true
    imageGenerator.requestedTimeToleranceBefore = .zero
    imageGenerator.requestedTimeToleranceAfter = .zero
    
    var processedFrames: [VideoDetectionFrame] = []
    var frameNumber = 0
    
    // Generate timestamps for frame extraction
    var currentTime: TimeInterval = 0
    let timestamps = stride(from: 0, to: duration, by: frameInterval).map { $0 }
    
    print("📈 [VideoMLManager] Generated \(timestamps.count) timestamps for processing")
    
    for (index, timestamp) in timestamps.enumerated() {
      if isCancelled {
        print("🛑 [VideoMLManager] Processing cancelled by user")
        break
      }
      
      frameNumber = index + 1
      currentProcessingStatus = "Processing frame \(frameNumber) of \(timestamps.count)..."
      
      do {
        // Extract frame at timestamp
        let time = CMTime(seconds: timestamp, preferredTimescale: 600)
        let cgImage = try imageGenerator.copyCGImage(at: time, actualTime: nil)
        
        // Convert to NSImage
        let nsImage = NSImage(cgImage: cgImage, size: NSSize(width: cgImage.width, height: cgImage.height))
        
        print("🖼️ [VideoMLManager] Extracted frame \(frameNumber) at \(String(format: "%.2f", timestamp))s")
        
        // Process frame with ML
        let frameStartTime = Date()
        
        // Wait for ML processing to complete
        await processFrameWithML(
          image: nsImage,
          model: model,
          confidenceThreshold: confidenceThreshold,
          iouThreshold: iouThreshold
        )
        
        let frameProcessingTime = Date().timeIntervalSince(frameStartTime)
        
        // Get the results from MLManager
        if let mlResult = mlManager.lastPredictionResult {
          let videoFrame = VideoDetectionFrame(
            timestamp: timestamp,
            frameNumber: frameNumber,
            detections: mlResult.detections,
            processingTime: frameProcessingTime
          )
          
          processedFrames.append(videoFrame)
          
          print("✅ [VideoMLManager] Frame \(frameNumber): \(mlResult.detections.count) detections in \(String(format: "%.2f", frameProcessingTime * 1000))ms")
        }
        
      } catch {
        print("❌ [VideoMLManager] Failed to process frame \(frameNumber) at \(String(format: "%.2f", timestamp))s: \(error)")
        // Continue with next frame
      }
      
      // Update progress
      processingProgress = Double(index + 1) / Double(timestamps.count)
    }
    
    print("🎯 [VideoMLManager] Frame processing completed: \(processedFrames.count)/\(timestamps.count) frames processed")
    return processedFrames
  }
  
  private func processFrameWithML(
    image: NSImage,
    model: VideoMLDemoView.ModelType,
    confidenceThreshold: Double,
    iouThreshold: Double
  ) async {
    switch model {
    case .yolo:
      await mlManager.predictWithYolo(
        image: image,
        confidenceThreshold: confidenceThreshold,
        iouThreshold: iouThreshold
      )
    case .tshirt:
      await mlManager.predictWithTShirt(
        image: image,
        confidenceThreshold: confidenceThreshold,
        iouThreshold: iouThreshold
      )
    }
  }
  
  // MARK: - Status Properties
  
  var isMLManagerReady: Bool {
    mlManager.isYoloModelLoaded && mlManager.isTShirtModelLoaded
  }
  
  var modelsStatus: String {
    mlManager.modelsStatus
  }
}
