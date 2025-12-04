//
//  CameraPreviewView.swift
//  Blinky
//
//  Created by Codex.
//

import SwiftUI
import AVFoundation

/// Focus tap info containing both device coordinates (for camera) and view coordinates (for indicator)
struct FocusTapInfo {
    /// Device coordinates (0-1 normalized, properly converted for camera sensor orientation)
    let devicePoint: CGPoint
    /// View coordinates (in the preview view's coordinate space, for displaying indicator)
    let viewPoint: CGPoint
}

struct CameraPreviewView: UIViewRepresentable {
    let session: AVCaptureSession?
    /// Called on tap with properly converted device coordinates and view coordinates
    var onFocusTap: ((FocusTapInfo) -> Void)?
    /// Called on long press (2 seconds) with device coordinates
    var onLongPress: ((CGPoint) -> Void)?
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    func makeUIView(context: Context) -> PreviewContainerView {
        let view = PreviewContainerView()
        view.videoPreviewLayer.session = session
        view.videoPreviewLayer.videoGravity = .resizeAspectFill
        view.onFocusTap = onFocusTap
        view.onLongPress = onLongPress
        return view
    }
    
    func updateUIView(_ uiView: PreviewContainerView, context: Context) {
        uiView.videoPreviewLayer.session = session
        uiView.onFocusTap = onFocusTap
        uiView.onLongPress = onLongPress
    }
    
    class Coordinator {}
}

final class PreviewContainerView: UIView {
    
    var onFocusTap: ((FocusTapInfo) -> Void)?
    var onLongPress: ((CGPoint) -> Void)?
    
    private var longPressTimer: Timer?
    private var touchStartPoint: CGPoint?
    private var touchStartDevicePoint: CGPoint?
    private var isLongPressTriggered = false
    
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
        longPressTimer?.invalidate()
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
    
    // MARK: - Touch Handling with Proper Coordinate Conversion
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let locationInView = touch.location(in: self)
        touchStartPoint = locationInView
        isLongPressTriggered = false
        
        // Convert touch point to camera device coordinates using the preview layer
        // This properly handles orientation and aspect ratio differences
        let devicePoint = videoPreviewLayer.captureDevicePointConverted(fromLayerPoint: locationInView)
        touchStartDevicePoint = devicePoint
        
        // Immediate focus on tap - pass both device coords (for camera) and view coords (for indicator)
        let tapInfo = FocusTapInfo(devicePoint: devicePoint, viewPoint: locationInView)
        onFocusTap?(tapInfo)
        
        // Start long press timer for AE/AF lock
        longPressTimer?.invalidate()
        longPressTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: false) { [weak self] _ in
            guard let self, let devicePoint = self.touchStartDevicePoint else { return }
            self.isLongPressTriggered = true
            
            DispatchQueue.main.async {
                self.onLongPress?(devicePoint)
            }
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first, let startPoint = touchStartPoint else { return }
        let currentPoint = touch.location(in: self)
        
        // If user moved too far, cancel long press
        let distance = hypot(currentPoint.x - startPoint.x, currentPoint.y - startPoint.y)
        if distance > 20 {
            longPressTimer?.invalidate()
            longPressTimer = nil
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        longPressTimer?.invalidate()
        longPressTimer = nil
        touchStartPoint = nil
        touchStartDevicePoint = nil
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        longPressTimer?.invalidate()
        longPressTimer = nil
        touchStartPoint = nil
        touchStartDevicePoint = nil
    }
    
    /// Convert a normalized point (0-1) to view coordinates for displaying focus indicator
    func viewPointFromDevicePoint(_ devicePoint: CGPoint) -> CGPoint {
        return videoPreviewLayer.layerPointConverted(fromCaptureDevicePoint: devicePoint)
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
