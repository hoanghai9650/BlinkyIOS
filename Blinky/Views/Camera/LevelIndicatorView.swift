//
//  LevelIndicatorView.swift
//  Blinky
//
//  Spirit level indicator to help users keep camera level
//

import SwiftUI
import Combine
import CoreMotion

struct LevelIndicatorView: View {
    @ObservedObject var motionManager: LevelMotionManager
    
    // When near zero, we hide the bar instead of snapping to green
    private let levelThreshold: Double = 1.0
    
    var body: some View {
        let angle = motionManager.displayAngle
        let absAngle = abs(angle)
        let clampedAngle = max(-10, min(10, angle))
        
        ZStack {
            // Reference line
            Rectangle()
                .fill(Color.white.opacity(0.25))
                .frame(width: 120, height: 1)
            
            // Dynamic indicator rotates opposite to device tilt
            HStack(spacing: 0) {
                Rectangle()
                    .fill(indicatorColor(absAngle))
                    .frame(width: 40, height: 2)
                
                Circle()
                    .fill(indicatorColor(absAngle))
                    .frame(width: 8, height: 8)
                
                Rectangle()
                    .fill(indicatorColor(absAngle))
                    .frame(width: 40, height: 2)
            }
            .rotationEffect(.degrees(-clampedAngle))
            .animation(.interactiveSpring(response: 0.15, dampingFraction: 0.7), value: clampedAngle)
        }
        // Rotate entire indicator based on device orientation
        .rotationEffect(.degrees(motionManager.orientationRotation))
        .animation(.easeInOut(duration: 0.2), value: motionManager.orientationRotation)
        .opacity(motionManager.isVisible ? 1 : 0)
        .animation(.easeOut(duration: 0.35), value: motionManager.isVisible)
    }
    
    private func indicatorColor(_ absAngle: Double) -> Color {
        absAngle <= levelThreshold ? Color.gold : Color.white
    }
}

// MARK: - Motion Manager

final class LevelMotionManager: ObservableObject {
    private let motionManager = CMMotionManager()
    private let motionQueue = OperationQueue()
    
    @Published private(set) var displayAngle: Double = 0 // degrees, orientation-adjusted
    @Published private(set) var orientationRotation: Double = 0 // rotation for UI (0, 90, -90, 180)
    @Published private(set) var isVisible: Bool = false
    
    private var orientation: DeviceOrientation = .portrait
    
    // Debounce for hiding
    private var hideWorkItem: DispatchWorkItem?
    private let hideDelay: TimeInterval = 0.3 // delay before hiding
    
    // Visibility bounds
    private let minVisibleAngle: Double = 1.0
    private let maxVisibleAngle: Double = 10.0
    
    init() {
        motionQueue.name = "com.blinky.levelmotion"
        motionQueue.maxConcurrentOperationCount = 1
        startUpdates()
    }
    
    deinit {
        motionManager.stopDeviceMotionUpdates()
        hideWorkItem?.cancel()
    }
    
    private func startUpdates() {
        guard motionManager.isDeviceMotionAvailable else { return }
        
        motionManager.deviceMotionUpdateInterval = 1.0 / 60.0 // 60 Hz
        motionManager.startDeviceMotionUpdates(to: motionQueue) { [weak self] motion, _ in
            guard let self, let motion else { return }
            
            // Orientation from gravity vector
            let gravity = motion.gravity
            let isLandscape = abs(gravity.x) > abs(gravity.y)
            let newOrientation: DeviceOrientation
            if isLandscape {
                newOrientation = gravity.x > 0 ? .landscapeRight : .landscapeLeft
            } else {
                newOrientation = gravity.y < 0 ? .portrait : .portraitUpsideDown
            }
            
            // Raw tilt angle relative to gravity (0 when level in current orientation)
            let rawAngleDeg = atan2(gravity.x, -gravity.y) * (180.0 / .pi)
            
            let orientationOffset: Double = {
                switch newOrientation {
                case .portrait: return 0
                case .portraitUpsideDown: return 180
                case .landscapeLeft: return -90
                case .landscapeRight: return 90
                }
            }()
            
            var adjusted = rawAngleDeg - orientationOffset
            // Normalize to [-180, 180]
            if adjusted > 180 { adjusted -= 360 }
            if adjusted < -180 { adjusted += 360 }
            
            // Clamp to a reasonable display range
            let clampedAngle = max(-45, min(45, adjusted))
            let absAngle = abs(clampedAngle)
            let shouldBeVisible = absAngle >= self.minVisibleAngle && absAngle <= self.maxVisibleAngle
            
            // Dispatch UI updates to main thread
            DispatchQueue.main.async {
                self.displayAngle = clampedAngle
                
                if newOrientation != self.orientation {
                    self.orientation = newOrientation
                    self.orientationRotation = {
                        switch newOrientation {
                        case .portrait: return 0
                        case .portraitUpsideDown: return 180
                        case .landscapeLeft: return 90
                        case .landscapeRight: return -90
                        }
                    }()
                }
                
                // Handle visibility with debounce for hiding
                self.updateVisibility(shouldBeVisible)
            }
        }
    }
    
    private func updateVisibility(_ shouldBeVisible: Bool) {
        if shouldBeVisible {
            // Show immediately, cancel any pending hide
            hideWorkItem?.cancel()
            hideWorkItem = nil
            if !isVisible {
                isVisible = true
            }
        } else {
            // Delay hiding with debounce
            if isVisible && hideWorkItem == nil {
                let workItem = DispatchWorkItem { [weak self] in
                    self?.isVisible = false
                    self?.hideWorkItem = nil
                }
                hideWorkItem = workItem
                DispatchQueue.main.asyncAfter(deadline: .now() + hideDelay, execute: workItem)
            }
        }
    }
}

private enum DeviceOrientation: Equatable {
    case portrait
    case portraitUpsideDown
    case landscapeLeft
    case landscapeRight
}

#Preview {
    ZStack {
        Color.black
        LevelIndicatorView(motionManager: LevelMotionManager())
    }
}

