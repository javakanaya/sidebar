//
//  MLManager.swift
//  Sidebar
//
//  Created by Java Kanaya Prada on 03/09/25.
//

import CoreML
import Vision
import SwiftUI

// MARK: - Detection Result Models

struct DetectionResult: Identifiable {
  let id = UUID()
  let boundingBox: CGRect
  let confidence: Float
  let label: String
  let color: Color
}

struct MLPredictionResult {
  let detections: [DetectionResult]
  let processingTime: TimeInterval
  let modelUsed: String
}

// MARK: - ML Manager

@MainActor
class MLManager: ObservableObject {
  @Published var isLoading = false
  @Published var errorMessage: String?
  @Published var lastPredictionResult: MLPredictionResult?
  
  // Models - Using generated classes
  private var yoloModel: Yolo11s?
  private var tshirtModel: TShirtDetectionModel?
  
  // YOLO class labels (from model description)
  private let yoloLabels = [
    "person", "bicycle", "car", "motorcycle", "airplane", "bus", "train", "truck", "boat",
    "traffic light", "fire hydrant", "stop sign", "parking meter", "bench", "bird", "cat",
    "dog", "horse", "sheep", "cow", "elephant", "bear", "zebra", "giraffe", "backpack",
    "umbrella", "handbag", "tie", "suitcase", "frisbee", "skis", "snowboard", "sports ball",
    "kite", "baseball bat", "baseball glove", "skateboard", "surfboard", "tennis racket",
    "bottle", "wine glass", "cup", "fork", "knife", "spoon", "bowl", "banana", "apple",
    "sandwich", "orange", "broccoli", "carrot", "hot dog", "pizza", "donut", "cake", "chair",
    "couch", "potted plant", "bed", "dining table", "toilet", "tv", "laptop", "mouse",
    "remote", "keyboard", "cell phone", "microwave", "oven", "toaster", "sink", "refrigerator",
    "book", "clock", "vase", "scissors", "teddy bear", "hair drier", "toothbrush"
  ]
  
  // T-shirt color labels (from model description)
  private let tshirtLabels = ["black", "blue", "grey", "white"]
  
  init() {
    loadModels()
  }
  
  // MARK: - Model Loading
  
  private func loadModels() {
    Task {
      await withTaskGroup(of: Void.self) { group in
        group.addTask { await self.loadYoloModel() }
        group.addTask { await self.loadTShirtModel() }
      }
    }
  }
  
  private func loadYoloModel() async {
    print("🔄 [MLManager] Starting to load YOLO model...")
    do {
      let model = try Yolo11s(configuration: MLModelConfiguration())
      await MainActor.run {
        self.yoloModel = model
        print("✅ [MLManager] Successfully loaded YOLO model using generated class")
      }
    } catch {
      print("❌ [MLManager] Failed to load YOLO model: \(error)")
      await MainActor.run {
        self.errorMessage = "Failed to load YOLO model: \(error.localizedDescription)"
      }
    }
  }
  
  private func loadTShirtModel() async {
    print("🔄 [MLManager] Starting to load T-Shirt model...")
    do {
      let model = try TShirtDetectionModel(configuration: MLModelConfiguration())
      await MainActor.run {
        self.tshirtModel = model
        print("✅ [MLManager] Successfully loaded T-Shirt model using generated class")
      }
    } catch {
      print("❌ [MLManager] Failed to load T-Shirt model: \(error)")
      await MainActor.run {
        self.errorMessage = "Failed to load T-Shirt model: \(error.localizedDescription)"
      }
    }
  }
  
  // MARK: - Prediction Methods
  
  func predictWithYolo(image: NSImage, confidenceThreshold: Double = 0.25, iouThreshold: Double = 0.7) async {
    print("🎯 [MLManager] Starting YOLO prediction with confidence=\(confidenceThreshold), iou=\(iouThreshold)")
    guard let model = yoloModel else {
      print("❌ [MLManager] YOLO model not loaded!")
      errorMessage = "YOLO model not loaded"
      return
    }
    print("✅ [MLManager] YOLO model is loaded, proceeding with prediction")
    
    await performYoloPrediction(
      image: image,
      model: model,
      confidenceThreshold: confidenceThreshold,
      iouThreshold: iouThreshold
    )
  }
  
  func predictWithTShirt(image: NSImage, confidenceThreshold: Double = 0.25, iouThreshold: Double = 0.7) async {
    print("👕 [MLManager] Starting T-Shirt prediction with confidence=\(confidenceThreshold), iou=\(iouThreshold)")
    guard let model = tshirtModel else {
      print("❌ [MLManager] T-Shirt model not loaded!")
      errorMessage = "T-Shirt model not loaded"
      return
    }
    print("✅ [MLManager] T-Shirt model is loaded, proceeding with prediction")
    
    await performTShirtPrediction(
      image: image,
      model: model,
      confidenceThreshold: confidenceThreshold,
      iouThreshold: iouThreshold
    )
  }
  
  private func performYoloPrediction(
    image: NSImage,
    model: Yolo11s,
    confidenceThreshold: Double,
    iouThreshold: Double
  ) async {
    print("🔄 [YOLO] Starting YOLO prediction process...")
    let startTime = Date()
    isLoading = true
    errorMessage = nil
    
    defer {
      isLoading = false
      print("🔄 [YOLO] Prediction process completed, loading state cleared")
    }
    
    do {
      print("📐 [YOLO] Original image size: \(image.size)")
      
      // Resize image to 640x640 as required by models
      guard let resizedImage = image.resized(to: NSSize(width: 640, height: 640)),
            let cgImage = resizedImage.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
        print("❌ [YOLO] Failed to process/resize image")
        errorMessage = "Failed to process image"
        return
      }
      
      print("✅ [YOLO] Image resized to 640x640 successfully")
      print("🔄 [YOLO] Converting CGImage to CVPixelBuffer...")
      
      // Create input for the generated model
      let pixelBuffer = try cgImageToPixelBuffer(cgImage)
      print("✅ [YOLO] CVPixelBuffer conversion successful")
      
      let input = Yolo11sInput(
        image: pixelBuffer,
        iouThreshold: iouThreshold,
        confidenceThreshold: confidenceThreshold
      )
      
      print("🔄 [YOLO] Running model prediction...")
      
      // Make prediction using the generated class
      let output = try await model.prediction(input: input)
      
      print("✅ [YOLO] Model prediction completed successfully")
      print("📊 [YOLO] Raw output - coordinates shape: \(output.coordinates.shape), confidence shape: \(output.confidence.shape)")
      
      // Parse results
      let detections = parseYoloOutput(output: output)
      let processingTime = Date().timeIntervalSince(startTime)
      
      print("📊 [YOLO] Parsed \(detections.count) detections in \(String(format: "%.2f", processingTime * 1000))ms")
      for (index, detection) in detections.prefix(5).enumerated() {
        print("   Detection \(index + 1): \(detection.label) (\(String(format: "%.2f", detection.confidence * 100))%)")
      }
      
      await MainActor.run {
        self.lastPredictionResult = MLPredictionResult(
          detections: detections,
          processingTime: processingTime,
          modelUsed: "YOLO11s"
        )
        print("✅ [YOLO] Results saved to UI state")
      }
      
    } catch {
      print("❌ [YOLO] Prediction failed with error: \(error)")
      await MainActor.run {
        self.errorMessage = "YOLO prediction failed: \(error.localizedDescription)"
      }
    }
  }
  
  private func performTShirtPrediction(
    image: NSImage,
    model: TShirtDetectionModel,
    confidenceThreshold: Double,
    iouThreshold: Double
  ) async {
    print("🔄 [T-Shirt] Starting T-Shirt prediction process...")
    let startTime = Date()
    isLoading = true
    errorMessage = nil
    
    defer {
      isLoading = false
      print("🔄 [T-Shirt] Prediction process completed, loading state cleared")
    }
    
    do {
      print("📐 [T-Shirt] Original image size: \(image.size)")
      
      // Resize image to 640x640 as required by models
      guard let resizedImage = image.resized(to: NSSize(width: 640, height: 640)),
            let cgImage = resizedImage.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
        print("❌ [T-Shirt] Failed to process/resize image")
        print("❌ [T-Shirt] Failed to process/resize image")
        errorMessage = "Failed to process image"
        return
      }
      
      print("✅ [T-Shirt] Image resized to 640x640 successfully")
      print("🔄 [T-Shirt] Converting CGImage to CVPixelBuffer...")
      
      // Create input for the generated model
      let pixelBuffer = try cgImageToPixelBuffer(cgImage)
      print("✅ [T-Shirt] CVPixelBuffer conversion successful")
      
      let input = TShirtDetectionModelInput(
        image: pixelBuffer,
        iouThreshold: iouThreshold,
        confidenceThreshold: confidenceThreshold
      )
      
      print("🔄 [T-Shirt] Running model prediction...")
      
      // Make prediction using the generated class
      let output = try await model.prediction(input: input)
      
      print("✅ [T-Shirt] Model prediction completed successfully")
      print("📊 [T-Shirt] Raw output - coordinates shape: \(output.coordinates.shape), confidence shape: \(output.confidence.shape)")
      
      // Parse results
      let detections = parseTShirtOutput(output: output)
      let processingTime = Date().timeIntervalSince(startTime)
      
      print("📊 [T-Shirt] Parsed \(detections.count) detections in \(String(format: "%.2f", processingTime * 1000))ms")
      for (index, detection) in detections.prefix(5).enumerated() {
        print("   Detection \(index + 1): \(detection.label) (\(String(format: "%.2f", detection.confidence * 100))%)")
      }
      
      await MainActor.run {
        self.lastPredictionResult = MLPredictionResult(
          detections: detections,
          processingTime: processingTime,
          modelUsed: "T-Shirt Detection"
        )
        print("✅ [T-Shirt] Results saved to UI state")
      }
      
    } catch {
      print("❌ [T-Shirt] Prediction failed with error: \(error)")
      await MainActor.run {
        self.errorMessage = "T-Shirt prediction failed: \(error.localizedDescription)"
      }
    }
  }
  
  private func parseYoloOutput(output: Yolo11sOutput) -> [DetectionResult] {
    print("🔍 [YOLO Parser] Starting to parse YOLO output...")
    var detections: [DetectionResult] = []
    
    // Get coordinates and confidence arrays
    let coordinatesArray = output.coordinates
    let confidenceArray = output.confidence
    
    // Parse detections based on array shape
    let numDetections = coordinatesArray.shape[0].intValue
    let numClasses = confidenceArray.shape[1].intValue
    
    print("📊 [YOLO Parser] Processing \(numDetections) potential detections across \(numClasses) classes")
    
    for i in 0..<numDetections {
      // Get bounding box coordinates (assuming format: x_center, y_center, width, height)
      let xCenter = coordinatesArray[[i, 0] as [NSNumber]].floatValue / 640.0 // Normalize
      let yCenter = coordinatesArray[[i, 1] as [NSNumber]].floatValue / 640.0
      let width = coordinatesArray[[i, 2] as [NSNumber]].floatValue / 640.0
      let height = coordinatesArray[[i, 3] as [NSNumber]].floatValue / 640.0
      
      // Convert to rectangle (top-left origin)
      let x = xCenter - width / 2
      let y = yCenter - height / 2
      let boundingBox = CGRect(x: CGFloat(x), y: CGFloat(y), width: CGFloat(width), height: CGFloat(height))
      
      // Find the class with highest confidence
      var maxConfidence: Float = 0
      var bestClassIndex = 0
      
      for j in 0..<numClasses {
        let confidence = confidenceArray[[i, j] as [NSNumber]].floatValue
        if confidence > maxConfidence {
          maxConfidence = confidence
          bestClassIndex = j
        }
      }
      
      // Only include detections above threshold and within label range
      if maxConfidence > 0.1 && bestClassIndex < yoloLabels.count {
        let label = yoloLabels[bestClassIndex]
        let color = colorForLabel(label)
        
        print("✅ [YOLO Parser] Detection \(i): \(label) (\(String(format: "%.2f", maxConfidence * 100))%) at (\(String(format: "%.2f", x)), \(String(format: "%.2f", y)))")
        
        detections.append(DetectionResult(
          boundingBox: boundingBox,
          confidence: maxConfidence,
          label: label,
          color: color
        ))
      } else {
        if maxConfidence <= 0.1 {
          print("⏭️ [YOLO Parser] Skipping detection \(i): confidence \(String(format: "%.2f", maxConfidence * 100))% too low")
        } else {
          print("⏭️ [YOLO Parser] Skipping detection \(i): invalid class index \(bestClassIndex)")
        }
      }
    }
    
    let sortedDetections = detections.sorted { $0.confidence > $1.confidence }
    print("🎯 [YOLO Parser] Final result: \(sortedDetections.count) valid detections after filtering and sorting")
    return sortedDetections
  }
  
  private func parseTShirtOutput(output: TShirtDetectionModelOutput) -> [DetectionResult] {
    print("🔍 [T-Shirt Parser] Starting to parse T-Shirt output...")
    var detections: [DetectionResult] = []
    
    // Get coordinates and confidence arrays
    let coordinatesArray = output.coordinates
    let confidenceArray = output.confidence
    
    // Parse detections based on array shape
    let numDetections = coordinatesArray.shape[0].intValue
    let numClasses = confidenceArray.shape[1].intValue
    
    print("📊 [T-Shirt Parser] Processing \(numDetections) potential detections across \(numClasses) classes")
    
    for i in 0..<numDetections {
      // Get bounding box coordinates (assuming format: x_center, y_center, width, height)
      let xCenter = coordinatesArray[[i, 0] as [NSNumber]].floatValue / 640.0 // Normalize
      let yCenter = coordinatesArray[[i, 1] as [NSNumber]].floatValue / 640.0
      let width = coordinatesArray[[i, 2] as [NSNumber]].floatValue / 640.0
      let height = coordinatesArray[[i, 3] as [NSNumber]].floatValue / 640.0
      
      // Convert to rectangle (top-left origin)
      let x = xCenter - width / 2
      let y = yCenter - height / 2
      let boundingBox = CGRect(x: CGFloat(x), y: CGFloat(y), width: CGFloat(width), height: CGFloat(height))
      
      // Find the class with highest confidence
      var maxConfidence: Float = 0
      var bestClassIndex = 0
      
      for j in 0..<numClasses {
        let confidence = confidenceArray[[i, j] as [NSNumber]].floatValue
        if confidence > maxConfidence {
          maxConfidence = confidence
          bestClassIndex = j
        }
      }
      
      // Only include detections above threshold and within label range
      if maxConfidence > 0.1 && bestClassIndex < tshirtLabels.count {
        let label = tshirtLabels[bestClassIndex]
        let color = colorForLabel(label)
        
        print("✅ [T-Shirt Parser] Detection \(i): \(label) (\(String(format: "%.2f", maxConfidence * 100))%) at (\(String(format: "%.2f", x)), \(String(format: "%.2f", y)))")
        
        detections.append(DetectionResult(
          boundingBox: boundingBox,
          confidence: maxConfidence,
          label: label,
          color: color
        ))
      } else {
        if maxConfidence <= 0.1 {
          print("⏭️ [T-Shirt Parser] Skipping detection \(i): confidence \(String(format: "%.2f", maxConfidence * 100))% too low")
        } else {
          print("⏭️ [T-Shirt Parser] Skipping detection \(i): invalid class index \(bestClassIndex)")
        }
      }
    }
    
    let sortedDetections = detections.sorted { $0.confidence > $1.confidence }
    print("🎯 [T-Shirt Parser] Final result: \(sortedDetections.count) valid detections after filtering and sorting")
    return sortedDetections
  }
  
  private func colorForLabel(_ label: String) -> Color {
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
  
  // MARK: - Helper Methods
  
  private func cgImageToPixelBuffer(_ cgImage: CGImage) throws -> CVPixelBuffer {
    print("🔄 [CVPixelBuffer] Converting CGImage to CVPixelBuffer...")
    let width = cgImage.width
    let height = cgImage.height
    
    print("📐 [CVPixelBuffer] Image dimensions: \(width)x\(height)")
    
    let attributes: [String: Any] = [
      kCVPixelBufferCGImageCompatibilityKey as String: true,
      kCVPixelBufferCGBitmapContextCompatibilityKey as String: true,
      kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32ARGB
    ]
    
    var pixelBuffer: CVPixelBuffer?
    let status = CVPixelBufferCreate(
      kCFAllocatorDefault,
      width,
      height,
      kCVPixelFormatType_32ARGB,
      attributes as CFDictionary,
      &pixelBuffer
    )
    
    guard status == kCVReturnSuccess, let buffer = pixelBuffer else {
      print("❌ [CVPixelBuffer] Failed to create pixel buffer with status: \(status)")
      throw NSError(domain: "MLManager", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to create pixel buffer"])
    }
    
    print("✅ [CVPixelBuffer] Pixel buffer created successfully")
    
    CVPixelBufferLockBaseAddress(buffer, CVPixelBufferLockFlags(rawValue: 0))
    defer { 
      CVPixelBufferUnlockBaseAddress(buffer, CVPixelBufferLockFlags(rawValue: 0))
      print("🔓 [CVPixelBuffer] Buffer unlocked")
    }
    
    let pixelData = CVPixelBufferGetBaseAddress(buffer)
    let rgbColorSpace = CGColorSpaceCreateDeviceRGB()
    
    guard let context = CGContext(
      data: pixelData,
      width: width,
      height: height,
      bitsPerComponent: 8,
      bytesPerRow: CVPixelBufferGetBytesPerRow(buffer),
      space: rgbColorSpace,
      bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue
    ) else {
      print("❌ [CVPixelBuffer] Failed to create graphics context")
      throw NSError(domain: "MLManager", code: 2, userInfo: [NSLocalizedDescriptionKey: "Failed to create graphics context"])
    }
    
    print("🎨 [CVPixelBuffer] Drawing image to context...")
    context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
    print("✅ [CVPixelBuffer] Image drawn to buffer successfully")
    
    return buffer
  }
  
  // MARK: - Model Status
  
  var isYoloModelLoaded: Bool { yoloModel != nil }
  var isTShirtModelLoaded: Bool { tshirtModel != nil }
  var modelsStatus: String {
    let yoloStatus = isYoloModelLoaded ? "✅" : "❌"
    let tshirtStatus = isTShirtModelLoaded ? "✅" : "❌"
    return "YOLO: \(yoloStatus) | T-Shirt: \(tshirtStatus)"
  }
}

// MARK: - NSImage Extension

extension NSImage {
  func resized(to newSize: NSSize) -> NSImage? {
    let newImage = NSImage(size: newSize)
    newImage.lockFocus()
    defer { newImage.unlockFocus() }
    
    let sourceRect = NSRect(origin: .zero, size: self.size)
    let destRect = NSRect(origin: .zero, size: newSize)
    
    self.draw(in: destRect, from: sourceRect, operation: .copy, fraction: 1.0)
    
    return newImage
  }
}
