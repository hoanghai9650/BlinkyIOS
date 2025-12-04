//
//  PhotoProcessingService.swift
//  Blinky
//
//  Created by Codex.
//

import UIKit

struct PhotoRenderBundle {
    let originalData: Data
    let previewData: Data
    let thumbnailData: Data
}

enum PhotoProcessingError: Error {
    case invalidPhotoData
    case renderingFailure
}

final class PhotoProcessingService {
    private let processingQueue = DispatchQueue(label: "com.blinky.photoProcessing", qos: .userInitiated)
    
    func renderOutputs(from data: Data) async throws -> PhotoRenderBundle {
        try await withCheckedThrowingContinuation { continuation in
            processingQueue.async {
                do {
                    let bundle = try self.renderBundle(from: data)
                    continuation.resume(returning: bundle)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    private func renderBundle(from data: Data) throws -> PhotoRenderBundle {
        // Image data already has correct orientation baked in from CameraService
        guard let image = UIImage(data: data) else {
            throw PhotoProcessingError.invalidPhotoData
        }
        
        // Generate different sizes
        let originalData = try resizedJPEGData(from: image, maxDimension: nil, compression: 0.95)
        let previewData = try resizedJPEGData(from: image, maxDimension: 1600, compression: 0.85)
        let thumbnailData = try resizedJPEGData(from: image, maxDimension: 512, compression: 0.75)
        
        return PhotoRenderBundle(
            originalData: originalData,
            previewData: previewData,
            thumbnailData: thumbnailData
        )
    }
    
    private func resizedJPEGData(from image: UIImage, maxDimension: CGFloat?, compression: CGFloat) throws -> Data {
        var outputImage = image
        
        // Resize if needed
        if let maxDim = maxDimension {
            let maxSide = max(image.size.width, image.size.height)
            if maxSide > maxDim {
                let scale = maxDim / maxSide
                let newSize = CGSize(
                    width: image.size.width * scale,
                    height: image.size.height * scale
                )
                outputImage = image.resized(to: newSize)
            }
        }
        
        guard let data = outputImage.jpegData(compressionQuality: compression) else {
            throw PhotoProcessingError.renderingFailure
        }
        return data
    }
}

// MARK: - UIImage Helpers

extension UIImage {
    func resized(to targetSize: CGSize) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: targetSize)
        return renderer.image { _ in
            draw(in: CGRect(origin: .zero, size: targetSize))
        }
    }
}
