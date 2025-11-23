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
    case ultraWide = "14mm"
    case wide = "24mm"
    case normal = "33mm"
    case portrait = "50mm"
    case telephoto = "70mm"
    
    var id: String { rawValue }
    
    var title: String {
        switch self {
        case .ultraWide: return "Ultra Wide"
        case .wide: return "Wide"
        case .normal: return "Normal"
        case .portrait: return "Portrait"
        case .telephoto: return "Tele"
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
