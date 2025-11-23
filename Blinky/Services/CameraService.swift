//
//  CameraService.swift
//  Blinky
//
//  Created by Codex.
//

import AVFoundation

enum CameraServiceError: Error {
    case configurationFailed
    case captureFailure
}

final class CameraService: NSObject {
    let session = AVCaptureSession()
    private let sessionQueue = DispatchQueue(label: "com.blinky.camera.session")
    private let photoOutput = AVCapturePhotoOutput()
    private var captureCompletion: ((Result<AVCapturePhoto, Error>) -> Void)?
    
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
    
    func startRunning() {
        sessionQueue.async {
            if !self.session.isRunning {
                self.session.startRunning()
            }
        }
    }
    
    func stopRunning() {
        sessionQueue.async {
            if self.session.isRunning {
                self.session.stopRunning()
            }
        }
    }
    
    func capturePhoto(settings: AVCapturePhotoSettings = AVCapturePhotoSettings(), completion: @escaping (Result<AVCapturePhoto, Error>) -> Void) {
        sessionQueue.async {
            guard self.captureCompletion == nil else { return }
            self.captureCompletion = completion
            var captureSettings = settings
            captureSettings.flashMode = .auto
            captureSettings.isHighResolutionPhotoEnabled = true
            self.photoOutput.capturePhoto(with: captureSettings, delegate: self)
        }
    }
}

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
