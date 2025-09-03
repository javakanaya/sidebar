//
//  MLDataModels.swift
//  Sidebar
//
//  Created by Java Kanaya Prada on 03/09/25.
//

import SwiftData
import SwiftUI
import Foundation

// MARK: - Detection Color Type Enum

enum DetectionColorType: String, CaseIterable, Codable {
  case blue = "blue"
  case red = "red"
  case green = "green"
  case black = "black"
  case gray = "gray"
  case primary = "primary"
  case orange = "orange"
  case purple = "purple"
  case yellow = "yellow"
  
  var swiftUIColor: Color {
    switch self {
    case .blue: return .blue
    case .red: return .red
    case .green: return .green
    case .black: return .black
    case .gray: return .gray
    case .primary: return .primary
    case .orange: return .orange
    case .purple: return .purple
    case .yellow: return .yellow
    }
  }
  
  static func colorType(for label: String) -> DetectionColorType {
    switch label.lowercased() {
    case "person": return .blue
    case "car", "truck", "bus": return .red
    case "bicycle", "motorcycle": return .green
    case "black": return .black
    case "blue": return .blue
    case "grey": return .gray
    case "white": return .primary
    default: return .orange
    }
  }
}

// MARK: - Detection Result Entity

@Model
class DetectionResultEntity {
  var id: UUID
  var boundingBoxX: Double
  var boundingBoxY: Double
  var boundingBoxWidth: Double
  var boundingBoxHeight: Double
  var confidence: Float
  var label: String
  var colorType: DetectionColorType
  var createdAt: Date
  
  init(id: UUID, boundingBoxX: Double, boundingBoxY: Double, boundingBoxWidth: Double, boundingBoxHeight: Double, confidence: Float, label: String, colorType: DetectionColorType) {
    self.id = id
    self.boundingBoxX = boundingBoxX
    self.boundingBoxY = boundingBoxY
    self.boundingBoxWidth = boundingBoxWidth
    self.boundingBoxHeight = boundingBoxHeight
    self.confidence = confidence
    self.label = label
    self.colorType = colorType
    self.createdAt = Date()
  }
  
  // Convenience initializer from DetectionResult
  convenience init(from detection: DetectionResult) {
    self.init(
      id: detection.id,
      boundingBoxX: detection.boundingBox.origin.x,
      boundingBoxY: detection.boundingBox.origin.y,
      boundingBoxWidth: detection.boundingBox.size.width,
      boundingBoxHeight: detection.boundingBox.size.height,
      confidence: detection.confidence,
      label: detection.label,
      colorType: DetectionColorType.colorType(for: detection.label)
    )
  }
  
  // Convert back to DetectionResult for UI
  func toDetectionResult() -> DetectionResult {
    let boundingBox = CGRect(
      x: boundingBoxX,
      y: boundingBoxY,
      width: boundingBoxWidth,
      height: boundingBoxHeight
    )
    
    return DetectionResult(
      boundingBox: boundingBox,
      confidence: confidence,
      label: label,
      color: colorType.swiftUIColor
    )
  }
}

// MARK: - Image ML Result Entity

@Model
class ImageMLResultEntity {
  var id: UUID
  var processedAt: Date
  var modelUsed: String
  var processingTime: TimeInterval
  var confidenceThreshold: Double
  var iouThreshold: Double
  
  // Image metadata
  var imageName: String?
  var imageWidth: Double?
  var imageHeight: Double?
  
  // Relationships
  @Relationship(deleteRule: .cascade)
  var detections: [DetectionResultEntity]
  
  init(id: UUID, processedAt: Date, modelUsed: String, processingTime: TimeInterval, confidenceThreshold: Double, iouThreshold: Double, imageName: String? = nil, imageWidth: Double? = nil, imageHeight: Double? = nil) {
    self.id = id
    self.processedAt = processedAt
    self.modelUsed = modelUsed
    self.processingTime = processingTime
    self.confidenceThreshold = confidenceThreshold
    self.iouThreshold = iouThreshold
    self.imageName = imageName
    self.imageWidth = imageWidth
    self.imageHeight = imageHeight
    self.detections = []
  }
  
  // Convenience initializer from MLPredictionResult
  convenience init(from result: MLPredictionResult, imageName: String? = nil, imageSize: CGSize? = nil, confidenceThreshold: Double, iouThreshold: Double) {
    self.init(
      id: UUID(),
      processedAt: Date(),
      modelUsed: result.modelUsed,
      processingTime: result.processingTime,
      confidenceThreshold: confidenceThreshold,
      iouThreshold: iouThreshold,
      imageName: imageName,
      imageWidth: imageSize.map { Double($0.width) },
      imageHeight: imageSize.map { Double($0.height) }
    )
    
    // Add detections
    self.detections = result.detections.map { DetectionResultEntity(from: $0) }
  }
  
  // Convert back to MLPredictionResult for UI
  func toMLPredictionResult() -> MLPredictionResult {
    let detectionResults = detections.map { $0.toDetectionResult() }
    return MLPredictionResult(
      detections: detectionResults,
      processingTime: processingTime,
      modelUsed: modelUsed
    )
  }
  
  var totalDetections: Int {
    detections.count
  }
}

// MARK: - Video Frame Result Entity

@Model
class VideoFrameResultEntity {
  var id: UUID
  var timestamp: TimeInterval
  var frameNumber: Int
  var processingTime: TimeInterval
  var createdAt: Date
  
  // Relationships
  @Relationship(deleteRule: .cascade)
  var detections: [DetectionResultEntity]
  
  init(id: UUID, timestamp: TimeInterval, frameNumber: Int, processingTime: TimeInterval) {
    self.id = id
    self.timestamp = timestamp
    self.frameNumber = frameNumber
    self.processingTime = processingTime
    self.createdAt = Date()
    self.detections = []
  }
  
  // Convenience initializer from VideoDetectionFrame
  convenience init(from frame: VideoDetectionFrame) {
    self.init(
      id: frame.id,
      timestamp: frame.timestamp,
      frameNumber: frame.frameNumber,
      processingTime: frame.processingTime
    )
    
    // Add detections
    self.detections = frame.detections.map { DetectionResultEntity(from: $0) }
  }
  
  // Convert back to VideoDetectionFrame for UI
  func toVideoDetectionFrame() -> VideoDetectionFrame {
    let detectionResults = detections.map { $0.toDetectionResult() }
    return VideoDetectionFrame(
      timestamp: timestamp,
      frameNumber: frameNumber,
      detections: detectionResults,
      processingTime: processingTime
    )
  }
}

// MARK: - Video ML Result Entity

@Model
class VideoMLResultEntity {
  var id: UUID
  var processedAt: Date
  var modelUsed: String
  var videoName: String
  var totalDuration: TimeInterval
  var totalProcessingTime: TimeInterval
  var frameRate: Double
  var confidenceThreshold: Double
  var iouThreshold: Double
  
  // Relationships
  @Relationship(deleteRule: .cascade)
  var processedFrames: [VideoFrameResultEntity]
  
  init(id: UUID, processedAt: Date, modelUsed: String, videoName: String, totalDuration: TimeInterval, totalProcessingTime: TimeInterval, frameRate: Double, confidenceThreshold: Double, iouThreshold: Double) {
    self.id = id
    self.processedAt = processedAt
    self.modelUsed = modelUsed
    self.videoName = videoName
    self.totalDuration = totalDuration
    self.totalProcessingTime = totalProcessingTime
    self.frameRate = frameRate
    self.confidenceThreshold = confidenceThreshold
    self.iouThreshold = iouThreshold
    self.processedFrames = []
  }
  
  // Convenience initializer from VideoMLResult
  convenience init(from result: VideoMLResult, confidenceThreshold: Double, iouThreshold: Double) {
    self.init(
      id: UUID(),
      processedAt: Date(),
      modelUsed: result.modelUsed,
      videoName: result.videoURL.lastPathComponent,
      totalDuration: result.totalDuration,
      totalProcessingTime: result.totalProcessingTime,
      frameRate: result.frameRate,
      confidenceThreshold: confidenceThreshold,
      iouThreshold: iouThreshold
    )
    
    // Add processed frames
    self.processedFrames = result.processedFrames.map { VideoFrameResultEntity(from: $0) }
  }
  
  // Convert back to VideoMLResult for UI (Note: URL will be nil since we only store the name)
  func toVideoMLResult() -> VideoMLResult {
    let frameResults = processedFrames.map { $0.toVideoDetectionFrame() }
    
    // Create a dummy URL since we can't reconstruct the original path
    let dummyURL = URL(fileURLWithPath: "/tmp/\(videoName)")
    
    return VideoMLResult(
      videoURL: dummyURL,
      totalDuration: totalDuration,
      processedFrames: frameResults,
      totalProcessingTime: totalProcessingTime,
      modelUsed: modelUsed,
      frameRate: frameRate,
      totalFramesProcessed: processedFrames.count
    )
  }
  
  // Computed properties
  var totalDetections: Int {
    processedFrames.reduce(0) { $0 + $1.detections.count }
  }
  
  var averageProcessingTime: TimeInterval {
    guard !processedFrames.isEmpty else { return 0 }
    return processedFrames.map { $0.processingTime }.reduce(0, +) / Double(processedFrames.count)
  }
  
  var detectionsPerSecond: Double {
    guard totalDuration > 0 else { return 0 }
    return Double(totalDetections) / totalDuration
  }
}
