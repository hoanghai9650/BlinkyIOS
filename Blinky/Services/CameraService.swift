//
//  CameraService.swift
//  Blinky
//
//  Created by Codex.
//

import AVFoundation
import UIKit
import CoreMotion

enum CameraServiceError: Error {
    case configurationFailed
    case captureFailure
    case invalidImageData
}

/// Camera type for switching between physical cameras
enum CameraType {
    case ultraWide  // 0.5x - 13mm
    case wide       // 1.0x+ - 24mm and digital zoom
    case telephoto  // For 100mm if available
}

final class CameraService: NSObject {
    let session = AVCaptureSession()
    private let sessionQueue = DispatchQueue(label: "com.blinky.camera.session")
    private let photoOutput = AVCapturePhotoOutput()
    private var captureCompletion: ((Result<Data, Error>) -> Void)?
    private(set) var currentDevice: AVCaptureDevice?
    private var currentCameraType: CameraType = .wide
    
    // Available cameras
    private var ultraWideCamera: AVCaptureDevice?
    private var wideCamera: AVCaptureDevice?
    private var telephotoCamera: AVCaptureDevice?
    
    // Core Motion for accurate device orientation (works even if UI is locked to portrait)
    private let motionManager = CMMotionManager()
    private var currentDeviceOrientation: UIDeviceOrientation = .portrait
    
    override init() {
        super.init()
        session.sessionPreset = .photo
        discoverCameras()
    }
    
    /// Discover all available back cameras
    private func discoverCameras() {
        let discoverySession = AVCaptureDevice.DiscoverySession(
            deviceTypes: [.builtInUltraWideCamera, .builtInWideAngleCamera, .builtInTelephotoCamera],
            mediaType: .video,
            position: .back
        )
        
        for device in discoverySession.devices {
            switch device.deviceType {
            case .builtInUltraWideCamera:
                ultraWideCamera = device
            case .builtInWideAngleCamera:
                wideCamera = device
            case .builtInTelephotoCamera:
                telephotoCamera = device
            default:
                break
            }
        }
        
        print("CameraService: Discovered cameras - UltraWide: \(ultraWideCamera != nil), Wide: \(wideCamera != nil), Telephoto: \(telephotoCamera != nil)")
    }
    
    func configureSession() {
        sessionQueue.async {
            self.session.beginConfiguration()
            defer { self.session.commitConfiguration() }
            
            // Start with wide-angle camera (24mm / 1.0x)
            guard let device = self.wideCamera,
                  let input = try? AVCaptureDeviceInput(device: device),
                  self.session.canAddInput(input) else {
                DispatchQueue.main.async {
                    self.captureCompletion?(.failure(CameraServiceError.configurationFailed))
                }
                return
            }
            self.session.inputs.forEach { self.session.removeInput($0) }
            self.session.addInput(input)
            self.currentDevice = device
            self.currentCameraType = .wide
            
            guard self.session.canAddOutput(self.photoOutput) else {
                DispatchQueue.main.async {
                    self.captureCompletion?(.failure(CameraServiceError.configurationFailed))
                }
                return
            }
            self.photoOutput.isHighResolutionCaptureEnabled = true
            self.session.addOutput(self.photoOutput)
        }
    }
    
    /// Switch to a specific camera type
    private func switchToCamera(_ type: CameraType) {
        let targetDevice: AVCaptureDevice?
        
        switch type {
        case .ultraWide:
            targetDevice = ultraWideCamera
        case .wide:
            targetDevice = wideCamera
        case .telephoto:
            targetDevice = telephotoCamera ?? wideCamera // Fall back to wide if no telephoto
        }
        
        guard let device = targetDevice, device != currentDevice else { return }
        
        do {
            let newInput = try AVCaptureDeviceInput(device: device)
            
            session.beginConfiguration()
            
            // Remove existing input
            session.inputs.forEach { session.removeInput($0) }
            
            // Add new input
            if session.canAddInput(newInput) {
                session.addInput(newInput)
                currentDevice = device
                currentCameraType = type
                print("CameraService: Switched to \(type) camera")
            }
            
            session.commitConfiguration()
        } catch {
            print("CameraService: Failed to switch camera - \(error)")
        }
    }
    
    /// Sets zoom factor with automatic camera switching:
    /// - 0.5x: Ultra-wide camera (13mm)
    /// - 1.0x-3.5x: Wide camera with digital zoom (24mm-50mm)
    /// - 4.0x+: Telephoto if available, otherwise wide with digital zoom (100mm)
    func setZoomFactor(_ factor: CGFloat, animated: Bool = true) {
        sessionQueue.async {
            // Determine which camera to use based on zoom factor
            if factor < 1.0 {
                // Ultra-wide camera (0.5x = 13mm)
                if self.currentCameraType != .ultraWide && self.ultraWideCamera != nil {
                    self.switchToCamera(.ultraWide)
                }
                // Ultra-wide is already at its native FOV, set zoom to 1.0
                self.applyZoom(1.0, animated: animated)
                
            } else if factor >= 4.0 {
                // 100mm - use telephoto if available
                if self.telephotoCamera != nil {
                    if self.currentCameraType != .telephoto {
                        self.switchToCamera(.telephoto)
                    }
                    // Calculate zoom relative to telephoto (typically 3x optical)
                    // For 4.2x total, if tele is 3x, we need 4.2/3 = 1.4x digital zoom on tele
                    let teleZoom = factor / 3.0
                    self.applyZoom(teleZoom, animated: animated)
                } else {
                    // No telephoto - use wide with digital zoom
                    if self.currentCameraType != .wide {
                        self.switchToCamera(.wide)
                    }
                    self.applyZoom(factor, animated: animated)
                }
                
            } else {
                // 1.0x - 3.5x: Wide camera with digital zoom (24mm, 35mm, 50mm)
                if self.currentCameraType != .wide {
                    self.switchToCamera(.wide)
                }
                self.applyZoom(factor, animated: animated)
            }
        }
    }
    
    /// Apply zoom factor to current device
    private func applyZoom(_ factor: CGFloat, animated: Bool) {
        guard let device = currentDevice else { return }
        
        do {
            try device.lockForConfiguration()
            
            let maxZoom = min(device.activeFormat.videoMaxZoomFactor, 10.0)
            let minZoom = device.minAvailableVideoZoomFactor
            let clampedFactor = min(max(factor, minZoom), maxZoom)
            
            if animated {
                device.ramp(toVideoZoomFactor: clampedFactor, withRate: 8.0)
            } else {
                device.videoZoomFactor = clampedFactor
            }
            
            device.unlockForConfiguration()
        } catch {
            print("CameraService: Failed to set zoom - \(error)")
        }
    }
    
    /// Enable/disable macro mode (ultra-wide camera with 2x zoom)
    func setMacroMode(_ enabled: Bool) {
        sessionQueue.async {
            if enabled {
                // Macro: switch to ultra-wide and apply 2x zoom
                if self.ultraWideCamera != nil {
                    if self.currentCameraType != .ultraWide {
                        self.switchToCamera(.ultraWide)
                    }
                    self.applyZoom(2.0, animated: true)
                } else {
                    // No ultra-wide available, fall back to wide with 2x
                    if self.currentCameraType != .wide {
                        self.switchToCamera(.wide)
                    }
                    self.applyZoom(2.0, animated: true)
                }
            }
            // Note: when disabled, ViewModel will call setZoomFactor to restore lens
        }
    }
    
    // MARK: - Focus & Exposure
    
    /// Tap to focus at a normalized point (0-1 coordinate space)
    func focus(at point: CGPoint) {
        sessionQueue.async {
            guard let device = self.currentDevice else { return }
            
            do {
                try device.lockForConfiguration()
                
                if device.isFocusPointOfInterestSupported {
                    device.focusPointOfInterest = point
                    device.focusMode = .autoFocus
                }
                
                if device.isExposurePointOfInterestSupported {
                    device.exposurePointOfInterest = point
                    device.exposureMode = .autoExpose
                }
                
                device.unlockForConfiguration()
            } catch {
                print("CameraService: Failed to focus - \(error)")
            }
        }
    }
    
    /// Lock focus and exposure at current values
    func lockFocusAndExposure() {
        sessionQueue.async {
            guard let device = self.currentDevice else { return }
            
            do {
                try device.lockForConfiguration()
                
                if device.isFocusModeSupported(.locked) {
                    device.focusMode = .locked
                }
                
                if device.isExposureModeSupported(.locked) {
                    device.exposureMode = .locked
                }
                
                device.unlockForConfiguration()
            } catch {
                print("CameraService: Failed to lock focus/exposure - \(error)")
            }
        }
    }
    
    /// Unlock focus and exposure (back to continuous auto)
    func unlockFocusAndExposure() {
        sessionQueue.async {
            guard let device = self.currentDevice else { return }
            
            do {
                try device.lockForConfiguration()
                
                if device.isFocusModeSupported(.continuousAutoFocus) {
                    device.focusMode = .continuousAutoFocus
                }
                
                if device.isExposureModeSupported(.continuousAutoExposure) {
                    device.exposureMode = .continuousAutoExposure
                }
                
                device.unlockForConfiguration()
            } catch {
                print("CameraService: Failed to unlock focus/exposure - \(error)")
            }
        }
    }
    
    /// Adjust exposure bias while locked
    func adjustExposureBias(_ bias: Float) {
        sessionQueue.async {
            guard let device = self.currentDevice else { return }
            
            let clampedBias = min(max(bias, device.minExposureTargetBias), device.maxExposureTargetBias)
            
            do {
                try device.lockForConfiguration()
                device.setExposureTargetBias(clampedBias)
                device.unlockForConfiguration()
            } catch {
                print("CameraService: Failed to adjust exposure bias - \(error)")
            }
        }
    }
    
    func startRunning() {
        startMotionUpdates()
        
        sessionQueue.async {
            if !self.session.isRunning {
                self.session.startRunning()
            }
        }
    }
    
    func stopRunning() {
        stopMotionUpdates()
        
        sessionQueue.async {
            if self.session.isRunning {
                self.session.stopRunning()
            }
        }
    }
    
    // MARK: - Core Motion for Device Orientation
    
    private func startMotionUpdates() {
        guard motionManager.isAccelerometerAvailable else {
            print("CameraService: Accelerometer not available")
            return
        }
        
        motionManager.accelerometerUpdateInterval = 0.1
        motionManager.startAccelerometerUpdates(to: .main) { [weak self] data, error in
            guard let self, let acceleration = data?.acceleration else { return }
            
            // Determine orientation from accelerometer data
            let orientation = self.orientationFromAcceleration(acceleration)
            if orientation != self.currentDeviceOrientation {
                self.currentDeviceOrientation = orientation
                print("CameraService: Device orientation changed to \(orientation.rawValue)")
            }
        }
    }
    
    private func stopMotionUpdates() {
        motionManager.stopAccelerometerUpdates()
    }
    
    private func orientationFromAcceleration(_ acceleration: CMAcceleration) -> UIDeviceOrientation {
        let x = acceleration.x
        let y = acceleration.y
        
        // Threshold to avoid jitter
        let threshold = 0.5
        
        if y < -threshold {
            return .portrait
        } else if y > threshold {
            return .portraitUpsideDown
        } else if x < -threshold {
            return .landscapeRight
        } else if x > threshold {
            return .landscapeLeft
        }
        
        // If no strong orientation detected, keep current
        return currentDeviceOrientation
    }
    
    func capturePhoto(settings: AVCapturePhotoSettings = AVCapturePhotoSettings(), completion: @escaping (Result<Data, Error>) -> Void) {
        sessionQueue.async {
            guard self.captureCompletion == nil else { return }
            self.captureCompletion = completion
            
            let captureSettings = settings
            captureSettings.flashMode = .auto
            
            self.photoOutput.capturePhoto(with: captureSettings, delegate: self)
        }
    }
}

@MainActor
extension CameraService: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        let completion = captureCompletion
        captureCompletion = nil
        
        if let error {
            completion?(.failure(error))
            return
        }
        
        guard let imageData = photo.fileDataRepresentation() else {
            completion?(.failure(CameraServiceError.invalidImageData))
            return
        }
        
        guard let provider = CGDataProvider(data: imageData as CFData) else {
            completion?(.failure(CameraServiceError.invalidImageData))
            return
        }
        
        guard let cgImage = CGImage(
            jpegDataProviderSource: provider,
            decode: nil,
            shouldInterpolate: true,
            intent: .defaultIntent
        ) else {
            completion?(.failure(CameraServiceError.invalidImageData))
            return
        }
        
        // Use orientation tracked by Core Motion accelerometer
        let deviceOrientation = currentDeviceOrientation
        let imageOrientation = deviceOrientation.uiImageOrientation
        print("CameraService: deviceOrientation=\(deviceOrientation.rawValue), imageOrientation=\(imageOrientation.rawValue)")
        
        let image = UIImage(cgImage: cgImage, scale: 1, orientation: imageOrientation)
        
        // Normalize orientation by redrawing (bakes orientation into pixels)
        let normalizedImage = image.normalizedOrientation()
        
        guard let finalData = normalizedImage.jpegData(compressionQuality: 0.95) else {
            completion?(.failure(CameraServiceError.invalidImageData))
            return
        }
        
        completion?(.success(finalData))
    }
}

// MARK: - UIDeviceOrientation to UIImage.Orientation

extension UIDeviceOrientation {
    var uiImageOrientation: UIImage.Orientation {
        switch self {
        case .portrait:
            return .right
        case .portraitUpsideDown:
            return .left
        case .landscapeLeft:
            // Home button on right → rotate 180°
            return .down
        case .landscapeRight:
            // Home button on left → no rotation
            return .up
        default:
            return .right // Default to portrait
        }
    }
}

// MARK: - UIImage Extension

extension UIImage {
    func normalizedOrientation() -> UIImage {
        guard imageOrientation != .up else { return self }
        
        UIGraphicsBeginImageContextWithOptions(size, false, scale)
        draw(in: CGRect(origin: .zero, size: size))
        let normalizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return normalizedImage ?? self
    }
}
