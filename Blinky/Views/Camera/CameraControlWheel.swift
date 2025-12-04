//
//  CameraControlWheel.swift
//  Blinky
//
//  Ruler-style horizontal wheel for camera parameter adjustment
//

import SwiftUI

struct CameraControlWheel: View {
    @Binding var value: Double
    let range: ClosedRange<Double>
    let step: Double
    let defaultValue: Double
    let isAuto: Bool
    let onScrollStarted: () -> Void
    
    // Visual config
    private let tickSpacing: CGFloat = 14
    private let majorTickInterval: Int = 5
    private let tickHeight: CGFloat = 14
    private let majorTickHeight: CGFloat = 22
    
    @State private var accumulatedOffset: CGFloat = 0
    @GestureState private var isDragging: Bool = false
    
    private var totalTicks: Int {
        Int((range.upperBound - range.lowerBound) / step) + 1
    }
    
    private var centerTickIndex: Double {
        (value - range.lowerBound) / step
    }
    
    private var defaultTickIndex: Int {
        Int((defaultValue - range.lowerBound) / step)
    }
    
    var body: some View {
        GeometryReader { proxy in
            let centerX = proxy.size.width / 2
            
            ZStack {
                // Tick marks
                tickMarksView(centerX: centerX, width: proxy.size.width)
                
                // Center indicator line
                Rectangle()
                    .fill(Color.primary)
                    .frame(width: 2.5, height: majorTickHeight + 10)
                    .position(x: centerX, y: proxy.size.height / 2)
            }
            .frame(height: proxy.size.height)
            .contentShape(Rectangle())
            .gesture(dragGesture)
        }
        .frame(height: 50)
        .opacity(isAuto ? 0.35 : 1.0)
        .allowsHitTesting(!isAuto)
    }
    
    @ViewBuilder
    private func tickMarksView(centerX: CGFloat, width: CGFloat) -> some View {
        Canvas { context, size in
            let visibleTickCount = Int(width / tickSpacing) + 20
            let currentIndex = Int(centerTickIndex.rounded())
            let startTickIndex = currentIndex - visibleTickCount / 2
            let endTickIndex = currentIndex + visibleTickCount / 2
            
            // Calculate sub-tick offset for smooth scrolling
            let fractionalOffset = (centerTickIndex - Double(currentIndex)) * Double(tickSpacing)
            
            for i in startTickIndex...endTickIndex {
                guard i >= 0 && i < totalTicks else { continue }
                
                let offsetFromCenter = Double(i - currentIndex) * Double(tickSpacing) - fractionalOffset
                let xPos = centerX + CGFloat(offsetFromCenter)
                
                guard xPos > -30 && xPos < width + 30 else { continue }
                
                let isMajorTick = i % majorTickInterval == 0
                let isDefaultTick = i == defaultTickIndex
                let height = isDefaultTick ? majorTickHeight + 4 : (isMajorTick ? majorTickHeight : tickHeight)
                let yStart = (size.height - height) / 2
                
                let tickPath = Path { path in
                    path.move(to: CGPoint(x: xPos, y: yStart))
                    path.addLine(to: CGPoint(x: xPos, y: yStart + height))
                }
                
                // Fade out ticks near edges
                let distanceFromCenter = abs(xPos - centerX)
                let edgeFade = max(0, 1 - (distanceFromCenter / (width * 0.45)))
                
                // Default tick gets primary color and higher opacity
                let baseOpacity: Double
                let tickColor: Color
                let lineWidth: CGFloat
                
                if isDefaultTick {
                    baseOpacity = 1.0
                    tickColor = Color.primary
                    lineWidth = 2.5
                } else if isMajorTick {
                    baseOpacity = 0.7
                    tickColor = .white
                    lineWidth = 1.5
                } else {
                    baseOpacity = 0.35
                    tickColor = .white
                    lineWidth = 1.0
                }
                
                let opacity = baseOpacity * edgeFade
                
                context.stroke(
                    tickPath,
                    with: .color(tickColor.opacity(opacity)),
                    lineWidth: lineWidth
                )
                
                // Draw small triangle indicator above default tick
                if isDefaultTick {
                    let triangleSize: CGFloat = 6
                    let trianglePath = Path { path in
                        path.move(to: CGPoint(x: xPos, y: yStart - 4))
                        path.addLine(to: CGPoint(x: xPos - triangleSize/2, y: yStart - 4 - triangleSize))
                        path.addLine(to: CGPoint(x: xPos + triangleSize/2, y: yStart - 4 - triangleSize))
                        path.closeSubpath()
                    }
                    context.fill(trianglePath, with: .color(Color.primary.opacity(opacity)))
                }
            }
        }
    }
    
    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: 1)
            .updating($isDragging) { _, state, _ in
                if !state {
                    state = true
                    // Notify that scrolling started (to disable auto mode)
                    DispatchQueue.main.async {
                        onScrollStarted()
                    }
                }
            }
            .onChanged { gesture in
                let delta = gesture.translation.width - accumulatedOffset
                accumulatedOffset = gesture.translation.width
                
                // Increased sensitivity for easier scrolling
                let sensitivity: CGFloat = 1.5
                let valueChange = -Double(delta) / Double(tickSpacing) * step * sensitivity
                let newValue = min(max(value + valueChange, range.lowerBound), range.upperBound)
                
                // Smooth update without snapping during drag
                value = newValue
            }
            .onEnded { _ in
                // Snap to nearest step on release
                let snappedValue = (value / step).rounded() * step
                withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                    value = min(max(snappedValue, range.lowerBound), range.upperBound)
                }
                accumulatedOffset = 0
            }
    }
}

// MARK: - Control Header with Animated Value

struct CameraControlHeader: View {
    let icon: String
    let title: String
    let displayValue: String
    let isAuto: Bool
    let onAutoToggle: () -> Void
    
    var body: some View {
        ZStack {
            // Center: Animated Value Display
            Text(displayValue)
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .contentTransition(.numericText(value: Double(displayValue.hashValue)))
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: displayValue)
            
            // Left & Right elements
            HStack(spacing: 12) {
                // Icon
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(Color.primary)
                    .frame(width: 32, height: 32)
                    .background(
                        Circle()
                            .fill(Color.primary.opacity(0.15))
                    )
                
                // Title
                Text(title)
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.7))
                
                Spacer()
                
                // Auto toggle
                Button {
                    onAutoToggle()
                } label: {
                    HStack(spacing: 4) {
                        Text("Auto")
                            .font(.caption.weight(.medium))
                        Image(systemName: "a.circle.fill")
                            .font(.system(size: 14))
                    }
                    .foregroundStyle(isAuto ? Color.primary : .white.opacity(0.5))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 7)
                    .background(
                        Capsule()
                            .fill(isAuto ? Color.primary.opacity(0.2) : Color.white.opacity(0.1))
                    )
                }
            }
        }
        .padding(.horizontal, 16)
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.background.ignoresSafeArea()
        
        VStack(spacing: 20) {
            CameraControlHeader(
                icon: "sun.max.fill",
                title: "Exposure",
                displayValue: "+0.0",
                isAuto: false,
                onAutoToggle: {}
            )
            
            CameraControlWheel(
                value: .constant(0.0),
                range: -3.0...3.0,
                step: 0.1,
                defaultValue: 0.0,
                isAuto: false,
                onScrollStarted: {}
            )
            .padding(.horizontal, 20)
        }
    }
}
