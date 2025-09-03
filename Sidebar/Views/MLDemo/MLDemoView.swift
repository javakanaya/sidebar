//
//  MLDemoView.swift
//  Sidebar
//
//  Created by Java Kanaya Prada on 03/09/25.
//

import SwiftUI
import UniformTypeIdentifiers

struct MLDemoView: View {
  @Environment(\.modelContext) private var modelContext
  @StateObject private var mlManager = MLManager()
  @State private var selectedImage: NSImage?
  @State private var selectedImageData: Data? // Store image data for persistence
  @State private var selectedImageName: String?
  @State private var selectedModel: ModelType = .yolo
  @State private var confidenceThreshold: Double = 0.25
  @State private var iouThreshold: Double = 0.7
  @State private var isShowingImagePicker = false
  
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
        
        // Image Selection
        imageSelectionSection
        
        // Results
        if let result = mlManager.lastPredictionResult {
          resultsSection(result)
        }
        
        Spacer(minLength: 50)
      }
      .padding(.horizontal, 24)
      .padding(.top, 20)
    }
    .navigationTitle("ML Demo")
    .onAppear {
      print("🎬 [MLDemoView] ML Demo view appeared")
      print("📊 [MLDemoView] Initial state - Model: \(selectedModel.rawValue), Confidence: \(confidenceThreshold), IoU: \(iouThreshold)")
      
      // Setup persistence service for auto-saving results
      mlManager.persistenceService = MLResultsPersistenceService(modelContext: modelContext)
    }
    .fileImporter(
      isPresented: $isShowingImagePicker,
      allowedContentTypes: [.image],
      allowsMultipleSelection: false
    ) { result in
      handleImageSelection(result)
    }
  }
  
  // MARK: - Header Section
  
  private var headerSection: some View {
    VStack(spacing: 16) {
      Image(systemName: "brain.head.profile")
        .font(.system(size: 60))
        .foregroundColor(.blue)
      
      Text("Machine Learning Demo")
        .font(.largeTitle)
        .fontWeight(.bold)
      
      Text("Test your YOLO and T-Shirt detection models")
        .font(.body)
        .foregroundColor(.secondary)
        .multilineTextAlignment(.center)
    }
  }
  
  // MARK: - Model Status Section
  
  private var modelStatusSection: some View {
    GroupBox("Model Status") {
      HStack {
        Text(mlManager.modelsStatus)
          .font(.system(.body, design: .monospaced))
        
        Spacer()
        
        if mlManager.isLoading {
          ProgressView()
            .scaleEffect(0.8)
        }
      }
      
      if let error = mlManager.errorMessage {
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
          print("🔄 [MLDemoView] Model selection changed from \(oldValue.rawValue) to \(newValue.rawValue)")
        }
        
        // Model Description
        HStack {
          Image(systemName: selectedModel.icon)
            .foregroundColor(.blue)
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
              print("🎚️ [MLDemoView] Confidence threshold changed from \(String(format: "%.2f", oldValue)) to \(String(format: "%.2f", newValue))")
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
              print("🎚️ [MLDemoView] IoU threshold changed from \(String(format: "%.2f", oldValue)) to \(String(format: "%.2f", newValue))")
            }
        }
      }
    }
  }
  
  // MARK: - Image Selection Section
  
  private var imageSelectionSection: some View {
    GroupBox("Image Input") {
      VStack(spacing: 16) {
        if let image = selectedImage {
          // Show selected image
          Image(nsImage: image)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(maxHeight: 300)
            .background(Color.gray.opacity(0.1))
            .cornerRadius(8)
          
          HStack {
            Button("Choose Different Image") {
              print("🖼️ [MLDemoView] User clicked 'Choose Different Image'")
              isShowingImagePicker = true
            }
            .buttonStyle(.bordered)
            
            Spacer()
            
            Button("Run Prediction") {
              print("🚀 [MLDemoView] User clicked 'Run Prediction'")
              runPrediction()
            }
            .buttonStyle(.borderedProminent)
            .disabled(mlManager.isLoading)
          }
        } else {
          // Image picker placeholder
          Button(action: { 
            print("🖼️ [MLDemoView] User clicked image selection placeholder")
            isShowingImagePicker = true 
          }) {
            VStack(spacing: 12) {
              Image(systemName: "photo.badge.plus")
                .font(.system(size: 40))
                .foregroundColor(.blue)
              
              Text("Select an Image")
                .font(.headline)
              
              Text("Choose an image to run ML detection")
                .font(.caption)
                .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(40)
            .background(Color.blue.opacity(0.1))
            .cornerRadius(12)
          }
          .buttonStyle(.plain)
        }
      }
    }
  }
  
  // MARK: - Results Section
  
  private func resultsSection(_ result: MLPredictionResult) -> some View {
    GroupBox("Detection Results") {
      VStack(alignment: .leading, spacing: 16) {
        // Summary
        HStack {
          VStack(alignment: .leading, spacing: 4) {
            Text("Model: \(result.modelUsed)")
              .font(.headline)
            Text("Processing Time: \(String(format: "%.2f", result.processingTime * 1000))ms")
              .font(.caption)
              .foregroundColor(.secondary)
          }
          
          Spacer()
          
          Text("\(result.detections.count) detections")
            .font(.subheadline)
            .fontWeight(.medium)
            .padding(.horizontal, 12)
            .padding(.vertical, 4)
            .background(Color.blue.opacity(0.1))
            .cornerRadius(6)
        }
        
        if result.detections.isEmpty {
          HStack {
            Image(systemName: "exclamationmark.circle")
              .foregroundColor(.orange)
            Text("No objects detected. Try lowering the confidence threshold.")
              .font(.caption)
              .foregroundColor(.secondary)
          }
          .padding()
          .background(Color.orange.opacity(0.1))
          .cornerRadius(8)
        } else {
          // Detection List
          LazyVStack(spacing: 8) {
            ForEach(result.detections.prefix(10)) { detection in // Show top 10
              HStack {
                Circle()
                  .fill(detection.color)
                  .frame(width: 12, height: 12)
                
                Text(detection.label.capitalized)
                  .font(.body)
                  .fontWeight(.medium)
                
                Spacer()
                
                Text("\(Int(detection.confidence * 100))%")
                  .font(.caption)
                  .foregroundColor(.secondary)
                  .padding(.horizontal, 8)
                  .padding(.vertical, 2)
                  .background(Color.gray.opacity(0.1))
                  .cornerRadius(4)
              }
              .padding(.horizontal, 8)
              .padding(.vertical, 4)
            }
          }
          
          if result.detections.count > 10 {
            Text("... and \(result.detections.count - 10) more")
              .font(.caption)
              .foregroundColor(.secondary)
              .padding(.top, 4)
          }
        }
      }
    }
  }
  
  // MARK: - Helper Methods
  
  private func handleImageSelection(_ result: Result<[URL], Error>) {
    print("🖼️ [MLDemoView] Handling image selection result...")
    switch result {
    case .success(let urls):
      if let url = urls.first {
        print("✅ [MLDemoView] Image selected from: \(url.lastPathComponent)")
        print("🔐 [MLDemoView] Full URL: \(url)")
        
        // For sandboxed apps, we need to access the security-scoped resource
        guard url.startAccessingSecurityScopedResource() else {
          print("❌ [MLDemoView] Failed to access security-scoped resource")
          mlManager.errorMessage = "Failed to access selected file"
          return
        }
        
        defer {
          url.stopAccessingSecurityScopedResource()
          print("🔓 [MLDemoView] Released security-scoped resource access")
        }
        
        // Try to load the image
        do {
          let imageData = try Data(contentsOf: url)
          print("📊 [MLDemoView] Image data loaded, size: \(imageData.count) bytes")
          
          if let image = NSImage(data: imageData) {
            selectedImage = image
            selectedImageData = imageData // Store for persistence
            selectedImageName = url.lastPathComponent
            print("✅ [MLDemoView] Image loaded successfully via Data, size: \(image.size)")
          } else {
            print("❌ [MLDemoView] Failed to create NSImage from Data")
            mlManager.errorMessage = "Unable to load the selected image file"
          }
        } catch {
          print("❌ [MLDemoView] Failed to load image data: \(error)")
          mlManager.errorMessage = "Failed to read image file: \(error.localizedDescription)"
        }
      } else {
        print("❌ [MLDemoView] No URL in selection result")
      }
    case .failure(let error):
      print("❌ [MLDemoView] Image selection failed: \(error)")
      mlManager.errorMessage = "Failed to load image: \(error.localizedDescription)"
    }
  }
  
  private func runPrediction() {
    guard let image = selectedImage else { 
      print("❌ [MLDemoView] No image selected for prediction")
      return 
    }
    
    print("🚀 [MLDemoView] Starting prediction with \(selectedModel.rawValue) model")
    print("⚙️ [MLDemoView] Parameters: confidence=\(confidenceThreshold), iou=\(iouThreshold)")
    
    Task {
      switch selectedModel {
      case .yolo:
        await mlManager.predictWithYolo(
          image: image,
          imageName: selectedImageName,
          imageData: selectedImageData,
          confidenceThreshold: confidenceThreshold,
          iouThreshold: iouThreshold
        )
      case .tshirt:
        await mlManager.predictWithTShirt(
          image: image,
          imageName: selectedImageName,
          imageData: selectedImageData,
          confidenceThreshold: confidenceThreshold,
          iouThreshold: iouThreshold
        )
      }
      print("🎯 [MLDemoView] Prediction task completed")
    }
  }
}

#Preview {
  MLDemoView()
}
