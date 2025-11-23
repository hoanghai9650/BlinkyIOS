//
//  PhotoProcessingService.swift
//  Blinky
//
//  Created by Codex.
//

import CoreImage
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
    private let context = CIContext(options: [.workingColorSpace: kCFNull as Any])
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
        guard let ciImage = CIImage(data: data, options: [.applyOrientationProperty: true]) else {
            throw PhotoProcessingError.invalidPhotoData
        }
        
        let previewData = try resizedData(from: ciImage, maxDimension: 1600, compression: 0.85)
        let thumbnailData = try resizedData(from: ciImage, maxDimension: 512, compression: 0.75)
        
        return PhotoRenderBundle(
            originalData: data,
            previewData: previewData,
            thumbnailData: thumbnailData
        )
    }
    
    private func resizedData(from ciImage: CIImage, maxDimension: CGFloat, compression: CGFloat) throws -> Data {
        let extent = ciImage.extent.integral
        let maxSide = max(extent.width, extent.height)
        guard maxSide > 0 else {
            throw PhotoProcessingError.renderingFailure
        }
        
        let scale = maxDimension / maxSide
        let transform = CGAffineTransform(scaleX: scale, y: scale)
        let scaledImage = ciImage.transformed(by: transform)
        
        guard let cgImage = context.createCGImage(scaledImage, from: scaledImage.extent) else {
            throw PhotoProcessingError.renderingFailure
        }
        
        let uiImage = UIImage(cgImage: cgImage, scale: UIScreen.main.scale, orientation: .up)
        guard let data = uiImage.jpegData(compressionQuality: compression) else {
            throw PhotoProcessingError.renderingFailure
        }
        return data
    }
}
