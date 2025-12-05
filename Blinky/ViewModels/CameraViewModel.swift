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
    
    @Published var selectedLens: LensProfile = .wide
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
    
    // MARK: - Focus & Exposure Lock
    
    @Published var isFocusLocked: Bool = false
    @Published var focusPoint: CGPoint? = nil
    @Published var focusExposureBias: Float = 0.0  // Adjustable exposure bias (works for both focus and lock)
    @Published var showFocusIndicator: Bool = false
    
    private var focusHideTask: Task<Void, Never>?
    
    // MARK: - Macro Mode
    
    @Published var isMacroEnabled: Bool = false
    
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
        // Apply macro mode changes - uses ultra-wide camera with 2x zoom
        $isMacroEnabled
            .dropFirst()
            .sink { [weak self] enabled in
                guard let self else { return }
                if enabled {
                    // Macro mode: ultra-wide camera with 2x zoom (cropped)
                    self.cameraService.setMacroMode(true)
                } else {
                    // Exit macro and restore to selected lens
                    self.cameraService.setMacroMode(false)
                    self.cameraService.setZoomFactor(self.selectedLens.zoomFactor, animated: true)
                }
            }
            .store(in: &cancellables)
        
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
        
        // Apply lens zoom changes (and disable macro when lens is manually selected)
        $selectedLens
            .dropFirst()
            .sink { [weak self] lens in
                guard let self else { return }
                // Disable macro mode when manually selecting a lens
                if self.isMacroEnabled {
                    self.isMacroEnabled = false
                }
                self.cameraService.setZoomFactor(lens.zoomFactor, animated: true)
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Auto Toggle
    
    func toggleAutoForCurrentControl() {
        switch activeControl {
        case .exposure:
            isExposureAuto.toggle()
            if isExposureAuto {
                // Reset to default value with animation
                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                    exposureValue = activeControl.defaultValue
                }
                settingsService.setAutoExposure()
            } else {
                settingsService.setExposureBias(Float(exposureValue))
            }
        case .temperature:
            isTemperatureAuto.toggle()
            if isTemperatureAuto {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                    temperatureValue = activeControl.defaultValue
                }
                settingsService.setAutoWhiteBalance()
            } else {
                settingsService.setWhiteBalance(temperature: Float(temperatureValue))
            }
        case .shutterSpeed:
            isShutterAuto.toggle()
            if isShutterAuto {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                    shutterSpeedIndex = activeControl.defaultValue
                }
                settingsService.setAutoShutter()
            } else if let shutterValue = ShutterSpeedValue.allCases[safe: Int(shutterSpeedIndex)] {
                let duration = CMTime(seconds: shutterValue.durationSeconds, preferredTimescale: 1000000)
                settingsService.setShutterSpeed(duration)
            }
        case .iso:
            isISOAuto.toggle()
            if isISOAuto {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                    isoValue = activeControl.defaultValue
                }
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
    
    func toggleMacro() {
        isMacroEnabled.toggle()
    }
    
    // MARK: - Focus & Exposure Control
    
    /// Tap to focus at normalized point - shows indicator with exposure slider
    func focusAt(_ point: CGPoint) {
        // Cancel any pending hide task
        focusHideTask?.cancel()
        
        focusPoint = point
        showFocusIndicator = true
        focusExposureBias = 0.0
        cameraService.focus(at: point)
        cameraService.adjustExposureBias(0.0)
        
        // Schedule auto-hide after 3 seconds (if not locked and not dragging)
        scheduleFocusHide()
    }
    
    /// Schedule the focus indicator to hide after delay
    func scheduleFocusHide() {
        focusHideTask?.cancel()
        focusHideTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: 3_000_000_000) // 3 seconds
            guard !Task.isCancelled, !isFocusLocked else { return }
            withAnimation(.easeOut(duration: 0.25)) {
                showFocusIndicator = false
                focusPoint = nil
            }
        }
    }
    
    /// Cancel auto-hide (when user is dragging exposure)
    func cancelFocusHide() {
        focusHideTask?.cancel()
    }
    
    /// Adjust exposure bias (works both focused and locked states)
    func adjustExposure(_ bias: Float) {
        focusExposureBias = min(max(bias, -3.0), 3.0)
        cameraService.adjustExposureBias(focusExposureBias)
    }
    
    /// Long press (2 sec) to lock focus & exposure
    func lockFocusAndExposure() {
        guard let point = focusPoint else { return }
        
        focusHideTask?.cancel()
        isFocusLocked = true
        cameraService.focus(at: point)
        cameraService.lockFocusAndExposure()
        cameraService.adjustExposureBias(focusExposureBias)
    }
    
    /// Tap elsewhere to dismiss focus indicator or unlock
    func dismissFocus() {
        focusHideTask?.cancel()
        
        if isFocusLocked {
            // Unlock
            isFocusLocked = false
            cameraService.unlockFocusAndExposure()
        }
        
        withAnimation(.easeOut(duration: 0.2)) {
            showFocusIndicator = false
            focusPoint = nil
        }
        focusExposureBias = 0.0
    }
    
    func capture(modelContext: ModelContext, locationDescription: String?) {
        captureState = .capturing
        
        let settings = AVCapturePhotoSettings()
 
        settings.flashMode = isFlashEnabled ? .on : .off
        
        cameraService.capturePhoto(settings: settings) { [weak self] result in
            guard let self else { return }
            switch result {
            case .success(let imageData):
                Task { await self.handleCapture(imageData: imageData, context: modelContext, locationDescription: locationDescription) }
            case .failure(let error):
                Task { @MainActor in
                    self.captureState = .failure(error.localizedDescription)
                }
            }
        }
    }
    
    private func handleCapture(imageData: Data, context: ModelContext, locationDescription: String?) async {
        await MainActor.run {
            self.captureState = .processing
        }
        
        do {
            let bundle = try await processingService.renderOutputs(from: imageData)
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
