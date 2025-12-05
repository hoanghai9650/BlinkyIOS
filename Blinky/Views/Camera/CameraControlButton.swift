//
//  CameraControlButton.swift
//  Blinky
//
//  Selection button for camera controls (EV, Temp, Shutter, ISO, Filter)
//

import SwiftUI

struct CameraControlButton: View {
    let icon: String
    let isSelected: Bool
    var isActive: Bool = false
    let action: () -> Void
    
    private let size: CGFloat = 48
    
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(isSelected ? .white : (isActive ? Color.primary : Color.icon))
                .frame(width: size, height: size)
                .background(
                    Circle()
                        .fill(isSelected ? Color.primary : Color.white.opacity(0.1))
                )
                .overlay(
                    Circle()
                        .strokeBorder(
                            isSelected ? Color.primary : (isActive ? Color.primary.opacity(0.5) : Color.white.opacity(0.15)),
                            lineWidth: 1.5
                        )
                )
        }
        .buttonStyle(.plain)
        .scaleEffect(isSelected ? 1.05 : 1.0)
        .animation(.spring(response: 0.25, dampingFraction: 0.7), value: isSelected)
    }
}

// MARK: - Camera Control Type

enum CameraControlType: String, CaseIterable, Identifiable {
    case exposure
    case temperature
    case shutterSpeed
    case iso
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .exposure: return "sun.max.fill"
        case .temperature: return "thermometer.medium"
        case .shutterSpeed: return "timelapse"
        case .iso: return "camera.aperture"
        }
    }
    
    var title: String {
        switch self {
        case .exposure: return "Exposure"
        case .temperature: return "Temperature"
        case .shutterSpeed: return "Shutter"
        case .iso: return "ISO"
        }
    }
    
    var range: ClosedRange<Double> {
        switch self {
        case .exposure: return -3.0...3.0
        case .temperature: return 1800...9800
        case .shutterSpeed: return 0...12 // Index into shutter speed array
        case .iso: return 50...6400
        }
    }
    
    var step: Double {
        switch self {
        case .exposure: return 0.1
        case .temperature: return 100
        case .shutterSpeed: return 1
        case .iso: return 50
        }
    }
    
    var defaultValue: Double {
        switch self {
        case .exposure: return 0.0
        case .temperature: return 5600
        case .shutterSpeed: return 6 // 1/125
        case .iso: return 200
        }
    }
    
    func formatValue(_ value: Double, isAuto: Bool) -> String {
        if isAuto { return "Auto" }
        
        switch self {
        case .exposure:
            let sign = value >= 0 ? "+" : ""
            return "\(sign)\(String(format: "%.1f", value))"
        case .temperature:
            return "\(Int(value))K"
        case .shutterSpeed:
            return ShutterSpeedValue.allCases[safe: Int(value)]?.displayString ?? "Auto"
        case .iso:
            return "\(Int(value))"
        }
    }
}

// MARK: - Shutter Speed Values

enum ShutterSpeedValue: String, CaseIterable, Identifiable {
    case oneOver4000 = "1/4000"
    case oneOver2000 = "1/2000"
    case oneOver1000 = "1/1000"
    case oneOver500 = "1/500"
    case oneOver250 = "1/250"
    case oneOver125 = "1/125"
    case oneOver60 = "1/60"
    case oneOver30 = "1/30"
    case oneOver15 = "1/15"
    case oneOver8 = "1/8"
    case oneOver4 = "1/4"
    case oneOver2 = "1/2"
    case one = "1\""
    
    var id: String { rawValue }
    
    var displayString: String { rawValue }
    
    var durationSeconds: Double {
        switch self {
        case .oneOver4000: return 1.0/4000
        case .oneOver2000: return 1.0/2000
        case .oneOver1000: return 1.0/1000
        case .oneOver500: return 1.0/500
        case .oneOver250: return 1.0/250
        case .oneOver125: return 1.0/125
        case .oneOver60: return 1.0/60
        case .oneOver30: return 1.0/30
        case .oneOver15: return 1.0/15
        case .oneOver8: return 1.0/8
        case .oneOver4: return 1.0/4
        case .oneOver2: return 1.0/2
        case .one: return 1.0
        }
    }
}

// MARK: - Array Safe Subscript

extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

// MARK: - Lens Pill Button

struct LensPillButton: View {
    let lens: LensProfile
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(lens.title)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(isSelected ? .white : .white.opacity(0.7))
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(isSelected ? Color.primary : Color.white.opacity(0.15))
                )
        }
        .glassEffect(.regular.interactive())
        .buttonStyle(.plain)
    }
}

// MARK: - Macro Button

struct MacroButton: View {
    let isActive: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: "camera.macro")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(isActive ? Color.gold : .white.opacity(0.8))
                .frame(width: 32, height: 32)
                .background(
                    Circle()
                        .fill(isActive ? Color.gold.opacity(0.2) : Color.black.opacity(0.4))
                        .background(
                            Circle()
                                .fill(.ultraThinMaterial)
                        )
                )
                .overlay(
                    Circle()
                        .strokeBorder(isActive ? Color.gold : Color.white.opacity(0.2), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Expandable Lens Selector (Overlay on Camera)

struct ExpandableLensSelector: View {
    @Binding var selectedLens: LensProfile
    @Binding var isMacroEnabled: Bool
    var onMacroToggle: () -> Void
    @State private var isExpanded: Bool = false
    
    var body: some View {
        HStack(spacing: 8) {
            // Macro button - hidden when lens options expanded
            if !isExpanded {
                MacroButton(isActive: isMacroEnabled) {
                    onMacroToggle()
                }
                .transition(.scale.combined(with: .opacity))
            }
            
            // Lens selector
            HStack(spacing: 6) {
                if isExpanded {
                    // Show all lens options
                    ForEach(LensProfile.allCases) { lens in
                        LensPillButton(
                            lens: lens,
                            isSelected: selectedLens == lens && !isMacroEnabled,
                            action: {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                    selectedLens = lens
                                    isExpanded = false
                                }
                            }
                        )
                        .transition(.scale.combined(with: .opacity))
                    }
                } else {
                    // Show only selected lens with zoom indicator
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            isExpanded = true
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Text(isMacroEnabled ? "Macro" : selectedLens.title)
                                .font(.system(size: 14, weight: .bold, design: .rounded))
                            
                            // Zoom factor indicator
                            Text(currentZoomLabel)
                                .font(.system(size: 11, weight: .medium))
                                .foregroundStyle(.white.opacity(0.6))
                            
                            Image(systemName: "chevron.up.chevron.down")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundStyle(.white.opacity(0.5))
                        }
                        .foregroundStyle(isMacroEnabled ? Color.gold : .white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(
                            Capsule()
                                .fill(Color.black.opacity(0.5))
                                .background(
                                    Capsule()
                                        .fill(.ultraThinMaterial)
                                )
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(
                Group {
                    if isExpanded {
                        Capsule()
                            .fill(Color.black.opacity(0.6))
                            .background(
                                Capsule()
                                    .fill(.ultraThinMaterial)
                            )
                    }
                }
            )
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isMacroEnabled)
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isExpanded)
        .onTapGesture { } // Prevent tap-through
        .simultaneousGesture(
            TapGesture()
                .onEnded { _ in
                    // Close when tapping outside options (if expanded)
                }
        )
    }
    
    private var currentZoomLabel: String {
        if isMacroEnabled {
            return "2x"
        }
        let factor = selectedLens.zoomFactor
        if factor < 1 {
            return String(format: "%.1fx", factor)
        } else if factor == floor(factor) {
            return "\(Int(factor))x"
        } else {
            return String(format: "%.1fx", factor)
        }
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.background.ignoresSafeArea()
        
        VStack(spacing: 24) {
            // Control buttons
            HStack(spacing: 12) {
                ForEach(CameraControlType.allCases) { type in
                    CameraControlButton(
                        icon: type.icon,
                        isSelected: type == .exposure,
                        action: {}
                    )
                }
                
                CameraControlButton(
                    icon: "circle.hexagongrid.fill",
                    isSelected: false,
                    action: {}
                )
            }
            
            // Expandable lens selector
            ExpandableLensSelector(
                selectedLens: .constant(.standard),
                isMacroEnabled: .constant(false),
                onMacroToggle: {}
            )
        }
    }
}

