//
//  Gyroscope3DModifier.swift
//  Blinky
//
//  Created by Codex.
//

import SwiftUI
import CoreMotion
import Combine
/// A motion manager class to handle device motion updates for 3D rotation effect
final class Gyroscope3DMotionManager: ObservableObject {
    private var motionManager: CMMotionManager?
    
    /// The current device pitch (forward/backward tilt) in degrees
    @Published var rotationX: Double = 0
    /// The current device roll (left/right tilt) in degrees
    @Published var rotationY: Double = 0
    
    private let maxRotation: Double
    
    /// Reference attitude captured at start - used to calculate relative rotation
    private var referenceAttitude: CMAttitude?
    
    init(maxRotation: Double = 15) {
        self.maxRotation = maxRotation
    }
    
    func startMonitoring() {
        motionManager = CMMotionManager()
        referenceAttitude = nil // Reset reference on start
        
        guard let motionManager = motionManager,
              motionManager.isDeviceMotionAvailable else {
            return
        }
        
        motionManager.deviceMotionUpdateInterval = 1.0 / 60.0 // 60Hz for smooth animation
        motionManager.startDeviceMotionUpdates(to: .main) { [weak self] motion, error in
            guard let self = self, let motion = motion, error == nil else { return }
            
            // Capture the initial attitude as reference point
            if self.referenceAttitude == nil {
                self.referenceAttitude = motion.attitude.copy() as? CMAttitude
            }
            
            // Calculate rotation relative to the reference attitude
            let attitude = motion.attitude
            if let reference = self.referenceAttitude {
                attitude.multiply(byInverseOf: reference)
            }
            
            // Convert radians to degrees and clamp within maxRotation
            // Pitch: tilting device forward/backward -> rotates image around X axis
            // Roll: tilting device left/right -> rotates image around Y axis
            let pitchDegrees = attitude.pitch * (180.0 / .pi)
            let rollDegrees = attitude.roll * (180.0 / .pi)
            
            let newRotationX = self.clamp(pitchDegrees * 0.8, min: -self.maxRotation, max: self.maxRotation)
            let newRotationY = self.clamp(rollDegrees * 0.8, min: -self.maxRotation, max: self.maxRotation)
            
            // Smooth the values with spring animation
            withAnimation(.interactiveSpring(response: 0.12, dampingFraction: 0.7)) {
                self.rotationX = newRotationX
                self.rotationY = newRotationY
            }
        }
    }
    
    func stopMonitoring() {
        motionManager?.stopDeviceMotionUpdates()
        motionManager = nil
        referenceAttitude = nil
        
        withAnimation(.easeOut(duration: 0.4)) {
            rotationX = 0
            rotationY = 0
        }
    }
    
    private func clamp(_ value: Double, min minValue: Double, max maxValue: Double) -> Double {
        return max(minValue, min(maxValue, value))
    }
}

/// A view modifier that adds 3D rotation effect based on device motion
struct Gyroscope3DModifier: ViewModifier {
    @StateObject private var motionManager: Gyroscope3DMotionManager
    
    let intensity: Double
    let perspective: Double
    let enabled: Bool
    
    init(intensity: Double = 1.0, perspective: Double = 0.5, enabled: Bool = true) {
        self.intensity = intensity
        self.perspective = perspective
        self.enabled = enabled
        _motionManager = StateObject(wrappedValue: Gyroscope3DMotionManager(
            maxRotation: 15 * intensity
        ))
    }
    
    func body(content: Content) -> some View {
        content
            // Apply 3D rotation based on device tilt
            .rotation3DEffect(
                .degrees(enabled ? -motionManager.rotationX : 0),
                axis: (x: 1, y: 0, z: 0),
                perspective: perspective
            )
            .rotation3DEffect(
                .degrees(enabled ? motionManager.rotationY : 0),
                axis: (x: 0, y: 1, z: 0),
                perspective: perspective
            )
            .onAppear {
                if enabled {
                    motionManager.startMonitoring()
                }
            }
            .onDisappear {
                motionManager.stopMonitoring()
            }
            .onChange(of: enabled) { _, newValue in
                if newValue {
                    motionManager.startMonitoring()
                } else {
                    motionManager.stopMonitoring()
                }
            }
    }
}

extension View {
    /// Adds a 3D rotation effect to the view based on device gyroscope motion
    /// - Parameters:
    ///   - intensity: The intensity of the 3D rotation effect (default: 1.0)
    ///   - perspective: The perspective depth for 3D effect (default: 0.5, lower = more dramatic)
    ///   - enabled: Whether the effect is enabled (default: true)
    /// - Returns: A view with the 3D rotation effect applied
    func gyroscope3D(intensity: Double = 1.0, perspective: Double = 0.5, enabled: Bool = true) -> some View {
        modifier(Gyroscope3DModifier(intensity: intensity, perspective: perspective, enabled: enabled))
    }
    
    /// Legacy alias for gyroscope3D
    func gyroscopeParallax(intensity: Double = 1.0, enabled: Bool = true) -> some View {
        modifier(Gyroscope3DModifier(intensity: intensity, perspective: 0.5, enabled: enabled))
    }
}
