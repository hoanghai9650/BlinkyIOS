//
//  CameraPreviewView.swift
//  Blinky
//
//  Created by Codex.
//

import SwiftUI
import AVFoundation

struct CameraPreviewView: UIViewRepresentable {
    let session: AVCaptureSession?
    
    func makeUIView(context: Context) -> PreviewContainerView {
        let view = PreviewContainerView()
        view.videoPreviewLayer.session = session
        view.videoPreviewLayer.videoGravity = .resizeAspectFill
        return view
    }
    
    func updateUIView(_ uiView: PreviewContainerView, context: Context) {
        uiView.videoPreviewLayer.session = session
    }
}

final class PreviewContainerView: UIView {
    
    override class var layerClass: AnyClass {
        AVCaptureVideoPreviewLayer.self
    }
    
    var videoPreviewLayer: AVCaptureVideoPreviewLayer {
        guard let layer = layer as? AVCaptureVideoPreviewLayer else {
            fatalError("Expected AVCaptureVideoPreviewLayer")
        }
        return layer
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupOrientationObserver()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupOrientationObserver()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        UIDevice.current.endGeneratingDeviceOrientationNotifications()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        // Update orientation whenever layout changes - this catches initial connection setup
        updatePreviewOrientation()
    }
    
    override func didMoveToWindow() {
        super.didMoveToWindow()
        // Update orientation when added to window hierarchy
        if window != nil {
            updatePreviewOrientation()
        }
    }
    
    private func setupOrientationObserver() {
        UIDevice.current.beginGeneratingDeviceOrientationNotifications()
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(deviceOrientationDidChange),
            name: UIDevice.orientationDidChangeNotification,
            object: nil
        )
    }
    
    @objc private func deviceOrientationDidChange() {
        updatePreviewOrientation()
    }
    
    private func updatePreviewOrientation() {
        guard let connection = videoPreviewLayer.connection else { return }
        
        let deviceOrientation = UIDevice.current.orientation
        
        // Use portrait as default if orientation is not valid
        let rotationAngle: CGFloat
        if deviceOrientation.isValidInterfaceOrientation {
            switch deviceOrientation {
            case .portrait:
                rotationAngle = 90
            case .portraitUpsideDown:
                rotationAngle = 270
            case .landscapeLeft:
                rotationAngle = 0
            case .landscapeRight:
                rotationAngle = 180
            default:
                rotationAngle = 90 // Default to portrait
            }
        } else {
            rotationAngle = 90 // Default to portrait
        }
        
        if connection.isVideoRotationAngleSupported(rotationAngle) {
            connection.videoRotationAngle = rotationAngle
        }
    }
}
