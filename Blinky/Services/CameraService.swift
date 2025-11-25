//
//  CameraService.swift
//  Blinky
//
//  Created by Codex.
//

import AVFoundation
import UIKit

enum CameraServiceError: Error {
    case configurationFailed
    case captureFailure
}

final class CameraService: NSObject {
    let session = AVCaptureSession()
    private let sessionQueue = DispatchQueue(label: "com.blinky.camera.session")
    private let photoOutput = AVCapturePhotoOutput()
    private var captureCompletion: ((Result<AVCapturePhoto, Error>) -> Void)?
    private(set) var currentDevice: AVCaptureDevice?
    
    /// Stores the current video rotation angle - updated on orientation changes
    private var currentVideoRotationAngle: CGFloat = 90 // Default portrait
    
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
    
    func startRunning() {
        // Enable device orientation updates
        UIDevice.current.beginGeneratingDeviceOrientationNotifications()
        
        // Observe orientation changes
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(deviceOrientationDidChange),
            name: UIDevice.orientationDidChangeNotification,
            object: nil
        )
        
        // Set initial orientation
        updateVideoRotationAngle()
        
        sessionQueue.async {
            if !self.session.isRunning {
                self.session.startRunning()
            }
        }
    }
    
    func stopRunning() {
        NotificationCenter.default.removeObserver(self, name: UIDevice.orientationDidChangeNotification, object: nil)
        UIDevice.current.endGeneratingDeviceOrientationNotifications()
        
        sessionQueue.async {
            if self.session.isRunning {
                self.session.stopRunning()
            }
        }
    }
    
    @objc private func deviceOrientationDidChange() {
        updateVideoRotationAngle()
    }
    
    private func updateVideoRotationAngle() {
        let deviceOrientation = UIDevice.current.orientation
        
        // Only update for valid orientations (not flat or unknown)
        guard deviceOrientation.isValidInterfaceOrientation else { return }
        
        let angle: CGFloat
        switch deviceOrientation {
        case .portrait:
            angle = 90
        case .portraitUpsideDown:
            angle = 270
        case .landscapeLeft:
            // Device rotated left (home button on right) → 0°
            angle = 0
        case .landscapeRight:
            // Device rotated right (home button on left) → 180°
            angle = 180
        default:
            return
        }
        
        currentVideoRotationAngle = angle
        
        // Update the connection immediately so it's ready for capture
        sessionQueue.async {
            if let connection = self.photoOutput.connection(with: .video) {
                connection.videoRotationAngle = angle
            }
        }
    }
    
    func capturePhoto(settings: AVCapturePhotoSettings = AVCapturePhotoSettings(), completion: @escaping (Result<AVCapturePhoto, Error>) -> Void) {
        sessionQueue.async {
            guard self.captureCompletion == nil else { return }
            self.captureCompletion = completion
            
            let captureSettings = settings
            captureSettings.flashMode = .auto
            captureSettings.maxPhotoDimensions = CMVideoDimensions(
                width: 4032,
                height: 3024
            )
            
            // Ensure connection has correct rotation angle before capture
            if let connection = self.photoOutput.connection(with: .video) {
                connection.videoRotationAngle = self.currentVideoRotationAngle
            }
            
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
            DispatchQueue.main.async {
                completion?(.failure(error))
            }
        } else {
            DispatchQueue.main.async {
                completion?(.success(photo))
            }
        }
    }
}
