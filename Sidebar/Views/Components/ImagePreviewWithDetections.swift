//
//  ImagePreviewWithDetections.swift
//  Sidebar
//
//  Created by Java Kanaya Prada on 03/09/25.
//

import SwiftUI

struct ImagePreviewWithDetections: View {
  let imageData: Data?
  let detections: [DetectionResultEntity]
  let imageSize: CGSize
  let maxWidth: CGFloat
  let maxHeight: CGFloat
  
  init(imageData: Data?, detections: [DetectionResultEntity], imageSize: CGSize, maxWidth: CGFloat = 300, maxHeight: CGFloat = 200) {
    self.imageData = imageData
    self.detections = detections
    self.imageSize = imageSize
    self.maxWidth = maxWidth
    self.maxHeight = maxHeight
  }
  
  var body: some View {
    Group {
      if let imageData = imageData,
         let nsImage = NSImage(data: imageData) {
        
        // Calculate display dimensions while maintaining aspect ratio
        let aspectRatio = imageSize.width / imageSize.height
        let displaySize = calculateDisplaySize(aspectRatio: aspectRatio)
        
        ZStack {
          // Background image
          Image(nsImage: nsImage)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: displaySize.width, height: displaySize.height)
            .clipped()
          
          // Overlay bounding boxes
          ForEach(detections.prefix(10), id: \.id) { detection in
            BoundingBoxOverlay(
              detection: detection,
              imageSize: imageSize,
              displaySize: displaySize
            )
          }
        }
        .frame(width: displaySize.width, height: displaySize.height)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
        
      } else {
        // Fallback when no image data is available
        RoundedRectangle(cornerRadius: 8)
          .fill(Color.gray.opacity(0.2))
          .frame(width: maxWidth, height: maxHeight)
          .overlay(
            VStack {
              Image(systemName: "photo")
                .font(.system(size: 40))
                .foregroundColor(.gray)
              Text("Image not available")
                .font(.caption)
                .foregroundColor(.secondary)
            }
          )
      }
    }
  }
  
  private func calculateDisplaySize(aspectRatio: CGFloat) -> CGSize {
    let displayWidth: CGFloat
    let displayHeight: CGFloat
    
    if aspectRatio > 1 { // Landscape
      displayWidth = min(maxWidth, imageSize.width)
      displayHeight = displayWidth / aspectRatio
    } else { // Portrait or square
      displayHeight = min(maxHeight, imageSize.height)
      displayWidth = displayHeight * aspectRatio
    }
    
    return CGSize(width: displayWidth, height: displayHeight)
  }
}

struct BoundingBoxOverlay: View {
  let detection: DetectionResultEntity
  let imageSize: CGSize
  let displaySize: CGSize
  
  var body: some View {
    let scaleX = displaySize.width / imageSize.width
    let scaleY = displaySize.height / imageSize.height
    
    // Scale the bounding box coordinates
    let scaledX = detection.boundingBoxX * scaleX
    let scaledY = detection.boundingBoxY * scaleY
    let scaledWidth = detection.boundingBoxWidth * scaleX
    let scaledHeight = detection.boundingBoxHeight * scaleY
    
    Rectangle()
      .stroke(detection.colorType.swiftUIColor, lineWidth: 2)
      .frame(width: scaledWidth, height: scaledHeight)
      .position(
        x: scaledX + scaledWidth / 2,
        y: scaledY + scaledHeight / 2
      )
      .overlay(
        // Label background
        VStack {
          HStack {
            Text(detection.label.capitalized)
              .font(.caption2)
              .foregroundColor(.white)
              .padding(.horizontal, 4)
              .padding(.vertical, 2)
              .background(detection.colorType.swiftUIColor)
              .cornerRadius(3)
            Spacer()
          }
          Spacer()
        }
        .position(
          x: scaledX + scaledWidth / 2,
          y: scaledY + 8
        )
      )
  }
}

#Preview {
  // Create sample detection data
  let sampleImageData = Data() // Empty data for preview
  let sampleDetections: [DetectionResultEntity] = []
  
  ImagePreviewWithDetections(
    imageData: sampleImageData,
    detections: sampleDetections,
    imageSize: CGSize(width: 640, height: 480)
  )
  .padding()
}
