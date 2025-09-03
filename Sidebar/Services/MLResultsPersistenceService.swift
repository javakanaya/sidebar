//
//  MLResultsPersistenceService.swift
//  Sidebar
//
//  Created by Java Kanaya Prada on 03/09/25.
//

import SwiftData
import SwiftUI
import Foundation

@MainActor
class MLResultsPersistenceService: ObservableObject {
  private var modelContext: ModelContext
  
  init(modelContext: ModelContext) {
    self.modelContext = modelContext
    print("🗄️ [MLResultsPersistenceService] Initialized with ModelContext")
  }
  
  // MARK: - Image ML Results
  
  func saveImageResult(_ result: MLPredictionResult, imageName: String? = nil, imagePath: String? = nil, imageData: Data? = nil, imageSize: CGSize? = nil, confidenceThreshold: Double, iouThreshold: Double) {
    print("💾 [MLResultsPersistenceService] Saving image ML result...")
    print("📊 [MLResultsPersistenceService] Result: \(result.detections.count) detections, model: \(result.modelUsed)")
    
    let imageResult = ImageMLResultEntity(
      from: result,
      imageName: imageName,
      imagePath: imagePath,
      imageData: imageData,
      imageSize: imageSize,
      confidenceThreshold: confidenceThreshold,
      iouThreshold: iouThreshold
    )
    
    do {
      modelContext.insert(imageResult)
      try modelContext.save()
      print("✅ [MLResultsPersistenceService] Image result saved successfully")
    } catch {
      print("❌ [MLResultsPersistenceService] Failed to save image result: \(error)")
    }
  }
  
  func fetchImageResults(limit: Int = 50) -> [ImageMLResultEntity] {
    print("📖 [MLResultsPersistenceService] Fetching image results (limit: \(limit))")
    
    let descriptor = FetchDescriptor<ImageMLResultEntity>(
      sortBy: [SortDescriptor(\.processedAt, order: .reverse)]
    )
    
    do {
      let results = try modelContext.fetch(descriptor)
      let limitedResults = Array(results.prefix(limit))
      print("✅ [MLResultsPersistenceService] Fetched \(limitedResults.count) image results")
      return limitedResults
    } catch {
      print("❌ [MLResultsPersistenceService] Failed to fetch image results: \(error)")
      return []
    }
  }
  
  func deleteImageResult(_ result: ImageMLResultEntity) {
    print("🗑️ [MLResultsPersistenceService] Deleting image result: \(result.id)")
    
    do {
      modelContext.delete(result)
      try modelContext.save()
      print("✅ [MLResultsPersistenceService] Image result deleted successfully")
    } catch {
      print("❌ [MLResultsPersistenceService] Failed to delete image result: \(error)")
    }
  }
  
  // MARK: - Video ML Results
  
  func saveVideoResult(_ result: VideoMLResult, confidenceThreshold: Double, iouThreshold: Double) {
    print("💾 [MLResultsPersistenceService] Saving video ML result...")
    print("📊 [MLResultsPersistenceService] Result: \(result.processedFrames.count) frames, \(result.totalDetections) total detections, model: \(result.modelUsed)")
    
    let videoResult = VideoMLResultEntity(
      from: result,
      confidenceThreshold: confidenceThreshold,
      iouThreshold: iouThreshold
    )
    
    do {
      modelContext.insert(videoResult)
      try modelContext.save()
      print("✅ [MLResultsPersistenceService] Video result saved successfully")
    } catch {
      print("❌ [MLResultsPersistenceService] Failed to save video result: \(error)")
    }
  }
  
  func fetchVideoResults(limit: Int = 50) -> [VideoMLResultEntity] {
    print("📖 [MLResultsPersistenceService] Fetching video results (limit: \(limit))")
    
    let descriptor = FetchDescriptor<VideoMLResultEntity>(
      sortBy: [SortDescriptor(\.processedAt, order: .reverse)]
    )
    
    do {
      let results = try modelContext.fetch(descriptor)
      let limitedResults = Array(results.prefix(limit))
      print("✅ [MLResultsPersistenceService] Fetched \(limitedResults.count) video results")
      return limitedResults
    } catch {
      print("❌ [MLResultsPersistenceService] Failed to fetch video results: \(error)")
      return []
    }
  }
  
  func deleteVideoResult(_ result: VideoMLResultEntity) {
    print("🗑️ [MLResultsPersistenceService] Deleting video result: \(result.id)")
    
    do {
      modelContext.delete(result)
      try modelContext.save()
      print("✅ [MLResultsPersistenceService] Video result deleted successfully")
    } catch {
      print("❌ [MLResultsPersistenceService] Failed to delete video result: \(error)")
    }
  }
  
  // MARK: - Search and Filter
  
  func searchImageResults(query: String, limit: Int = 50) -> [ImageMLResultEntity] {
    print("🔍 [MLResultsPersistenceService] Searching image results with query: '\(query)'")
    
    let predicate = #Predicate<ImageMLResultEntity> { result in
      result.modelUsed.localizedStandardContains(query) ||
      (result.imageName?.localizedStandardContains(query) ?? false)
    }
    
    let descriptor = FetchDescriptor<ImageMLResultEntity>(
      predicate: predicate,
      sortBy: [SortDescriptor(\.processedAt, order: .reverse)]
    )
    
    do {
      let results = try modelContext.fetch(descriptor)
      let limitedResults = Array(results.prefix(limit))
      print("✅ [MLResultsPersistenceService] Found \(limitedResults.count) image results")
      return limitedResults
    } catch {
      print("❌ [MLResultsPersistenceService] Failed to search image results: \(error)")
      return []
    }
  }
  
  func searchVideoResults(query: String, limit: Int = 50) -> [VideoMLResultEntity] {
    print("🔍 [MLResultsPersistenceService] Searching video results with query: '\(query)'")
    
    let predicate = #Predicate<VideoMLResultEntity> { result in
      result.modelUsed.localizedStandardContains(query) ||
      result.videoName.localizedStandardContains(query)
    }
    
    let descriptor = FetchDescriptor<VideoMLResultEntity>(
      predicate: predicate,
      sortBy: [SortDescriptor(\.processedAt, order: .reverse)]
    )
    
    do {
      let results = try modelContext.fetch(descriptor)
      let limitedResults = Array(results.prefix(limit))
      print("✅ [MLResultsPersistenceService] Found \(limitedResults.count) video results")
      return limitedResults
    } catch {
      print("❌ [MLResultsPersistenceService] Failed to search video results: \(error)")
      return []
    }
  }
  
  // MARK: - Statistics
  
  func getTotalImageResults() -> Int {
    let descriptor = FetchDescriptor<ImageMLResultEntity>()
    do {
      let count = try modelContext.fetchCount(descriptor)
      print("📊 [MLResultsPersistenceService] Total image results: \(count)")
      return count
    } catch {
      print("❌ [MLResultsPersistenceService] Failed to count image results: \(error)")
      return 0
    }
  }
  
  func getTotalVideoResults() -> Int {
    let descriptor = FetchDescriptor<VideoMLResultEntity>()
    do {
      let count = try modelContext.fetchCount(descriptor)
      print("📊 [MLResultsPersistenceService] Total video results: \(count)")
      return count
    } catch {
      print("❌ [MLResultsPersistenceService] Failed to count video results: \(error)")
      return 0
    }
  }
  
  // MARK: - Cleanup
  
  func deleteAllImageResults() {
    print("🧹 [MLResultsPersistenceService] Deleting all image results...")
    
    do {
      let descriptor = FetchDescriptor<ImageMLResultEntity>()
      let results = try modelContext.fetch(descriptor)
      
      for result in results {
        modelContext.delete(result)
      }
      
      try modelContext.save()
      print("✅ [MLResultsPersistenceService] Deleted \(results.count) image results")
    } catch {
      print("❌ [MLResultsPersistenceService] Failed to delete all image results: \(error)")
    }
  }
  
  func deleteAllVideoResults() {
    print("🧹 [MLResultsPersistenceService] Deleting all video results...")
    
    do {
      let descriptor = FetchDescriptor<VideoMLResultEntity>()
      let results = try modelContext.fetch(descriptor)
      
      for result in results {
        modelContext.delete(result)
      }
      
      try modelContext.save()
      print("✅ [MLResultsPersistenceService] Deleted \(results.count) video results")
    } catch {
      print("❌ [MLResultsPersistenceService] Failed to delete all video results: \(error)")
    }
  }
}
