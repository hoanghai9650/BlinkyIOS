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

final class CameraService: NSObject {
    let session = AVCaptureSession()
    private let sessionQueue = DispatchQueue(label: "com.blinky.camera.session")
    private let photoOutput = AVCapturePhotoOutput()
    private var captureCompletion: ((Result<Data, Error>) -> Void)?
    private(set) var currentDevice: AVCaptureDevice?
    
    // Core Motion for accurate device orientation (works even if UI is locked to portrait)
    private let motionManager = CMMotionManager()
    private var currentDeviceOrientation: UIDeviceOrientation = .portrait
    
    override init() {
        super.init()
        session.sessionPreset = .photo
    }
    
    func configureSession() {
        sessionQueue.async {
            self.session.beginConfiguration()
            defer { self.session.commitConfiguration() }
            
            guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
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
    
    func setZoomFactor(_ factor: CGFloat, animated: Bool = true) {
        sessionQueue.async {
            guard let device = self.currentDevice else { return }
            
            do {
                try device.lockForConfiguration()
                
                let maxZoom = min(device.activeFormat.videoMaxZoomFactor, 10.0)
                let clampedFactor = min(max(factor, 1.0), maxZoom)
                
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
