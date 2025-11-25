//
//  PhotoAsset.swift
//  Blinky
//
//  Created by Codex.
//

import Foundation
import SwiftData

@Model
final class PhotoAsset: Identifiable {
    @Attribute(.unique) var id: UUID
    var originalURL: URL
    var previewURL: URL
    var thumbnailURL: URL
    var filterName: String
    var lens: String
    var iso: Double
    var aperture: Double
    var shutterSpeed: String
    var locationDescription: String?
    var capturedAt: Date
    
    init(
        id: UUID = UUID(),
        originalURL: URL,
        previewURL: URL,
        thumbnailURL: URL,
        filterName: String,
        lens: String,
        iso: Double,
        aperture: Double,
        shutterSpeed: String,
        locationDescription: String?,
        capturedAt: Date = .now
    ) {
        self.id = id
        self.originalURL = originalURL
        self.previewURL = previewURL
        self.thumbnailURL = thumbnailURL
        self.filterName = filterName
        self.lens = lens
        self.iso = iso
        self.aperture = aperture
        self.shutterSpeed = shutterSpeed
        self.locationDescription = locationDescription
        self.capturedAt = capturedAt
    }
}

struct PhotoMetadata {
    var filterName: String
    var lens: String
    var iso: Double
    var aperture: Double
    var shutterSpeed: String
    var locationDescription: String?
}

enum LensProfile: String, CaseIterable, Identifiable {
    case ultraWide = "13mm"
    case wide = "24mm"
    case standard = "35mm"
    case portrait = "50mm"
    case telephoto = "100mm"
    
    var id: String { rawValue }
    
    var focalLength: Int {
        switch self {
        case .ultraWide: return 13
        case .wide: return 24
        case .standard: return 35
        case .portrait: return 50
        case .telephoto: return 100
        }
    }
    
    var title: String {
        "\(focalLength)"
    }
    
    /// Zoom factor relative to standard 24mm lens (1.0x)
    var zoomFactor: CGFloat {
        switch self {
        case .ultraWide: return 0.5   // Ultra wide angle
        case .wide: return 1.0        // Default (1x)
        case .standard: return 1.5    // ~35mm equivalent
        case .portrait: return 2.0    // 2x zoom
        case .telephoto: return 4.0   // 4x zoom (100mm = ~4x of 24mm)
        }
    }
}

enum FilterLUT: String, CaseIterable, Identifiable {
    case none = "None"
    case cinematic = "Cinematic"
    case vivid = "Vivid"
    case noir = "Noir"
    case film = "Classic Film"
    
    var id: String { rawValue }
}
