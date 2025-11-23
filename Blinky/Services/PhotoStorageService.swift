//
//  PhotoStorageService.swift
//  Blinky
//
//  Created by Codex.
//

import Foundation

enum PhotoStorageError: Error {
    case directoryCreationFailed
    case fileWriteFailed
}

final class PhotoStorageService {
    static let capturesDirectoryName = "BlinkyCaptures"
    static func capturesDirectory(fileManager: FileManager = .default) -> URL {
        let documentURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        return documentURL.appendingPathComponent(Self.capturesDirectoryName, isDirectory: true)
    }
    static func fileURL(for filename: String, fileManager: FileManager = .default) -> URL {
        capturesDirectory(fileManager: fileManager).appendingPathComponent(filename)
    }
    
    private let fileManager: FileManager
    private let baseURL: URL

    init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
        self.baseURL = Self.capturesDirectory(fileManager: fileManager)
        createDirectoryIfNeeded()
    }

    func persist(bundle: PhotoRenderBundle, metadata: PhotoMetadata) throws -> PhotoAsset {
        let id = UUID()
        let originalURL = baseURL.appendingPathComponent("\(id.uuidString)_original.jpg")
        let previewURL = baseURL.appendingPathComponent("\(id.uuidString)_preview.jpg")
        let thumbnailURL = baseURL.appendingPathComponent("\(id.uuidString)_thumb.jpg")
        
        do {
            try bundle.originalData.write(to: originalURL, options: .atomic)
            try bundle.previewData.write(to: previewURL, options: .atomic)
            try bundle.thumbnailData.write(to: thumbnailURL, options: .atomic)
        } catch {
            throw PhotoStorageError.fileWriteFailed
        }
        
        return PhotoAsset(
            id: id,
            originalURL: originalURL,
            previewURL: previewURL,
            thumbnailURL: thumbnailURL,
            filterName: metadata.filterName,
            lens: metadata.lens,
            iso: metadata.iso,
            aperture: metadata.aperture,
            shutterSpeed: metadata.shutterSpeed,
            locationDescription: metadata.locationDescription,
            capturedAt: .now
        )
    }
    
    func deleteFiles(for asset: PhotoAsset) {
        for url in [asset.originalURL, asset.previewURL, asset.thumbnailURL] {
            try? fileManager.removeItem(at: url)
        }
    }
    
    private func createDirectoryIfNeeded() {
        guard !fileManager.fileExists(atPath: baseURL.path) else { return }
        do {
            try fileManager.createDirectory(at: baseURL, withIntermediateDirectories: true)
        } catch {
            fatalError("Failed to create storage directory: \(error)")
        }
    }
}
