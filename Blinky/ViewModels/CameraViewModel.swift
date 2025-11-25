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
    
    // MARK: - Session State
    
    @Published private(set) var session: AVCaptureSession?
    @Published private(set) var captureState: CaptureState = .idle
    @Published private(set) var lastSavedAsset: PhotoAsset?
    
    // MARK: - Camera Settings
    
    @Published var selectedLens: LensProfile = .standard
    @Published var selectedFilter: FilterLUT = .none
    
    // MARK: - Active Control Selection
    
    @Published var activeControl: CameraControlType = .exposure
    
    // MARK: - Control Values
    
    @Published var exposureValue: Double = 0.0  // EV: -3.0 to +3.0
    @Published var temperatureValue: Double = 5600  // Kelvin: 1800 to 9800
    @Published var shutterSpeedIndex: Double = 5  // Index into ShutterSpeedValue array
    @Published var isoValue: Double = 200  // ISO: 50 to 6400
    
    // MARK: - Auto Mode States
    
    @Published var isExposureAuto: Bool = true
    @Published var isTemperatureAuto: Bool = true
    @Published var isShutterAuto: Bool = true
    @Published var isISOAuto: Bool = true
    
    // MARK: - Camera Options
    
    @Published var storeLocation: Bool = true
    @Published var showGrid: Bool = false
    @Published var whiteBalancePreset: CameraSettingsService.WhiteBalancePreset = .auto
    
    // MARK: - Flash
    
    @Published var isFlashEnabled: Bool = false
    
    // MARK: - Services
    
    private let cameraService = CameraService()
    private let settingsService = CameraSettingsService()
    private let processingService = PhotoProcessingService()
    private let storageService = PhotoStorageService()
    
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Computed Properties
    
    var currentControlValue: Binding<Double> {
        switch activeControl {
        case .exposure:
            return Binding(
                get: { self.exposureValue },
                set: { self.exposureValue = $0 }
            )
        case .temperature:
            return Binding(
                get: { self.temperatureValue },
                set: { self.temperatureValue = $0 }
            )
        case .shutterSpeed:
            return Binding(
                get: { self.shutterSpeedIndex },
                set: { self.shutterSpeedIndex = $0 }
            )
        case .iso:
            return Binding(
                get: { self.isoValue },
                set: { self.isoValue = $0 }
            )
        }
    }
    
    var currentAutoState: Bool {
        switch activeControl {
        case .exposure: return isExposureAuto
        case .temperature: return isTemperatureAuto
        case .shutterSpeed: return isShutterAuto
        case .iso: return isISOAuto
        }
    }
    
    var currentDisplayValue: String {
        let value: Double
        let isAuto: Bool
        
        switch activeControl {
        case .exposure:
            value = exposureValue
            isAuto = isExposureAuto
        case .temperature:
            value = temperatureValue
            isAuto = isTemperatureAuto
        case .shutterSpeed:
            value = shutterSpeedIndex
            isAuto = isShutterAuto
        case .iso:
            value = isoValue
            isAuto = isISOAuto
        }
        
        return activeControl.formatValue(value, isAuto: isAuto)
    }
    
    var currentShutterSpeed: ShutterSpeedValue {
        ShutterSpeedValue.allCases[safe: Int(shutterSpeedIndex)] ?? .oneOver125
    }
    
    // MARK: - Init
    
    init() {
        session = cameraService.session
        setupBindings()
    }
    
    // MARK: - Setup
    
    private func setupBindings() {
        // Apply exposure changes
        $exposureValue
            .dropFirst()
            .filter { [weak self] _ in !(self?.isExposureAuto ?? true) }
            .sink { [weak self] value in
                self?.settingsService.setExposureBias(Float(value))
            }
            .store(in: &cancellables)
        
        // Apply temperature changes
        $temperatureValue
            .dropFirst()
            .filter { [weak self] _ in !(self?.isTemperatureAuto ?? true) }
            .sink { [weak self] value in
                self?.settingsService.setWhiteBalance(temperature: Float(value))
            }
            .store(in: &cancellables)
        
        // Apply ISO changes
        $isoValue
            .dropFirst()
            .filter { [weak self] _ in !(self?.isISOAuto ?? true) }
            .sink { [weak self] value in
                self?.settingsService.setISO(Float(value))
            }
            .store(in: &cancellables)
        
        // Apply shutter speed changes
        $shutterSpeedIndex
            .dropFirst()
            .filter { [weak self] _ in !(self?.isShutterAuto ?? true) }
            .sink { [weak self] value in
                guard let shutterValue = ShutterSpeedValue.allCases[safe: Int(value)] else { return }
                let duration = CMTime(seconds: shutterValue.durationSeconds, preferredTimescale: 1000000)
                self?.settingsService.setShutterSpeed(duration)
            }
            .store(in: &cancellables)
        
        // Apply white balance preset changes
        $whiteBalancePreset
            .dropFirst()
            .sink { [weak self] preset in
                self?.settingsService.applyWhiteBalancePreset(preset)
            }
            .store(in: &cancellables)
        
        // Apply lens zoom changes
        $selectedLens
            .dropFirst()
            .sink { [weak self] lens in
                self?.cameraService.setZoomFactor(lens.zoomFactor, animated: true)
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Auto Toggle
    
    func toggleAutoForCurrentControl() {
        switch activeControl {
        case .exposure:
            isExposureAuto.toggle()
            if isExposureAuto {
                settingsService.setAutoExposure()
            } else {
                settingsService.setExposureBias(Float(exposureValue))
            }
        case .temperature:
            isTemperatureAuto.toggle()
            if isTemperatureAuto {
                settingsService.setAutoWhiteBalance()
            } else {
                settingsService.setWhiteBalance(temperature: Float(temperatureValue))
            }
        case .shutterSpeed:
            isShutterAuto.toggle()
            if isShutterAuto {
                settingsService.setAutoShutter()
            } else if let shutterValue = ShutterSpeedValue.allCases[safe: Int(shutterSpeedIndex)] {
                let duration = CMTime(seconds: shutterValue.durationSeconds, preferredTimescale: 1000000)
                settingsService.setShutterSpeed(duration)
            }
        case .iso:
            isISOAuto.toggle()
            if isISOAuto {
                settingsService.setAutoISO()
            } else {
                settingsService.setISO(Float(isoValue))
            }
        }
    }
    
    /// Turn off auto mode for current control (called when user scrolls the wheel)
    func disableAutoForCurrentControl() {
        switch activeControl {
        case .exposure:
            if isExposureAuto {
                isExposureAuto = false
                settingsService.setExposureBias(Float(exposureValue))
            }
        case .temperature:
            if isTemperatureAuto {
                isTemperatureAuto = false
                settingsService.setWhiteBalance(temperature: Float(temperatureValue))
            }
        case .shutterSpeed:
            if isShutterAuto {
                isShutterAuto = false
                if let shutterValue = ShutterSpeedValue.allCases[safe: Int(shutterSpeedIndex)] {
                    let duration = CMTime(seconds: shutterValue.durationSeconds, preferredTimescale: 1000000)
                    settingsService.setShutterSpeed(duration)
                }
            }
        case .iso:
            if isISOAuto {
                isISOAuto = false
                settingsService.setISO(Float(isoValue))
            }
        }
    }
    
    // MARK: - Camera Control
    
    func configureCamera() {
        cameraService.configureSession()
        
        // Configure settings service with camera device
        if let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) {
            settingsService.configure(with: device)
        }
    }
    
    func startSession() {
        cameraService.startRunning()
    }
    
    func stopSession() {
        cameraService.stopRunning()
    }
    
    func toggleFlash() {
        isFlashEnabled.toggle()
    }
    
    func capture(modelContext: ModelContext, locationDescription: String?) {
        captureState = .capturing
        
        let settings = AVCapturePhotoSettings()
 
        settings.flashMode = isFlashEnabled ? .on : .off
        
        cameraService.capturePhoto(settings: settings) { [weak self] result in
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
                self.captureState = .failure("Cannot read photo data.")
            }
            return
        }
        
        do {
            let bundle = try await processingService.renderOutputs(from: data)
            let metadata = PhotoMetadata(
                filterName: selectedFilter.rawValue,
                lens: selectedLens.rawValue,
                iso: isoValue,
                aperture: 1.8, // Fixed for now
                shutterSpeed: currentShutterSpeed.displayString,
                locationDescription: storeLocation ? locationDescription : nil
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
