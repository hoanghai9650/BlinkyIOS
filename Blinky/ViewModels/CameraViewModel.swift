//
//  CameraViewModel.swift
//  Blinky
//
//  Created by Codex.
//

import SwiftUI
import AVFoundation
import SwiftData
import Combine

@MainActor
final class CameraViewModel: ObservableObject {

    enum CaptureState: Equatable {
        case idle
        case capturing
        case processing
        case saved
        case failure(String)
        
        static func == (lhs: CaptureState, rhs: CaptureState) -> Bool {
            switch (lhs, rhs) {
            case (.idle, .idle), (.capturing, .capturing), (.processing, .processing), (.saved, .saved):
                return true
            case (.failure(let lhsMessage), .failure(let rhsMessage)):
                return lhsMessage == rhsMessage
            default:
                return false
            }
        }
    }
    
    @Published private(set) var session: AVCaptureSession?
    @Published private(set) var captureState: CaptureState = .idle
    @Published private(set) var lastSavedAsset: PhotoAsset?
    
    @Published var selectedLens: LensProfile = .wide
    @Published var selectedFilter: FilterLUT = .none
    @Published var isoValue: Double = 200
    @Published var aperture: Double = 1.8
    @Published var shutterSpeed: ShutterSpeedOption = .oneOneTwentyFifth
    
    private let cameraService = CameraService()
    private let processingService = PhotoProcessingService()
    private let storageService = PhotoStorageService()
    
    init() {
        session = cameraService.session
    }
    
    func configureCamera() {
        cameraService.configureSession()
    }
    
    func startSession() {
        cameraService.startRunning()
    }
    
    func stopSession() {
        cameraService.stopRunning()
    }
    
    func capture(modelContext: ModelContext, locationDescription: String?) {
        captureState = .capturing
        cameraService.capturePhoto { [weak self] result in
            guard let self else { return }
            switch result {
            case .success(let photo):
                Task { await self.handleCapture(photo: photo, context: modelContext, locationDescription: locationDescription) }
            case .failure(let error):
                Task { @MainActor in
                    self.captureState = .failure(error.localizedDescription)
                }
            }
        }
    }
    
    private func handleCapture(photo: AVCapturePhoto, context: ModelContext, locationDescription: String?) async {
        await MainActor.run {
            self.captureState = .processing
        }
        
        guard let data = photo.fileDataRepresentation() else {
            await MainActor.run {
                self.captureState = .failure("Không thể đọc dữ liệu ảnh.")
            }
            return
        }
        
        do {
            let bundle = try await processingService.renderOutputs(from: data)
            let metadata = PhotoMetadata(
                filterName: selectedFilter.rawValue,
                lens: selectedLens.rawValue,
                iso: isoValue,
                aperture: aperture,
                shutterSpeed: shutterSpeed.displayValue,
                locationDescription: locationDescription
            )
            let asset = try storageService.persist(bundle: bundle, metadata: metadata)
            context.insert(asset)
            try context.save()
            
            await MainActor.run {
                self.lastSavedAsset = asset
                self.captureState = .saved
            }
        } catch {
            await MainActor.run {
                self.captureState = .failure(error.localizedDescription)
            }
        }
    }
    
    func resetStatus() {
        captureState = .idle
    }
}

enum ShutterSpeedOption: String, CaseIterable, Identifiable {
    case oneThirtieth = "1/30"
    case oneSixtieth = "1/60"
    case oneOneTwentyFifth = "1/125"
    case oneTwoFiftieth = "1/250"
    case oneFiveHundredth = "1/500"
    
    var id: String { rawValue }
    
    var displayValue: String {
        rawValue + "s"
    }
}
