//
//  CameraView.swift
//  Blinky
//
//  Created by Codex.
//

import SwiftUI
import SwiftData
import UIKit

struct CameraView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var locationService: LocationService
    @StateObject private var viewModel = CameraViewModel()
    let isActive: Bool
    
    @State private var showFilterSheet = false
    @State private var showOptionsSheet = false
    
    @Namespace private var sheetAnimation
    @Namespace private var filterNameSpace
    
    var body: some View {
        NavigationView{
            GeometryReader { proxy in
                ZStack {
                    Color.background.ignoresSafeArea()
                    
                    VStack(spacing: 0) {
                        // Top bar
                        topBar
                            .padding(.horizontal, 20)
                        
                        Spacer()
                        
                        // Camera preview with lens overlay
                        cameraPreviewSection(proxy: proxy)
                        
                        Spacer()
                        
                        // Control buttons row
                        controlButtonsRow
                            .padding(.horizontal, 20)
                            .padding(.bottom, 16)
                        
                        // Control wheel section
                        controlWheelSection
                            .padding(.horizontal, 16)
                            .padding(.bottom, 16)
                        
                        // Capture button
                        captureButton
                            .padding(.bottom, 8)
                    }
                }
            }
            .onAppear {
                viewModel.configureCamera()
                if isActive {
                    viewModel.startSession()
                }
                locationService.requestAccessIfNeeded()
                locationService.refreshLocation()
            }
            .onChange(of: isActive) { active in
                if active {
                    viewModel.startSession()
                } else {
                    viewModel.stopSession()
                }
            }
            .onDisappear {
                viewModel.stopSession()
            }
            .sheet(isPresented: $showFilterSheet) {
                FilterSheetView(
                    selectedFilter: $viewModel.selectedFilter,
                    namespace: sheetAnimation
                    
                ).navigationTransition(.zoom(sourceID: "filter", in:  filterNameSpace))
            }
            .sheet(isPresented: $showOptionsSheet) {
                CameraOptionsSheet(
                    storeLocation: $viewModel.storeLocation,
                    showGrid: $viewModel.showGrid,
                    whiteBalancePreset: $viewModel.whiteBalancePreset,
                    namespace: sheetAnimation
                ).navigationTransition(
                    .zoom(sourceID: "optionsSheet", in:  sheetAnimation)
                )
            }
        }
        .edgesIgnoringSafeArea(.bottom)
        
    }
    
    // MARK: - Top Bar
    
    private var topBar: some View {
        HStack {
            // Flash toggle
            Button {
                viewModel.toggleFlash()
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: viewModel.isFlashEnabled ? "bolt.fill" : "bolt.slash.fill")
                        .font(.system(size: 14, weight: .medium))
                }
                .foregroundStyle(viewModel.isFlashEnabled ? Color.gold : Color.icon)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(
                    Capsule()
                        .fill(Color.white.opacity(0.1))
                )
            }
            
            Spacer()
            
            // Capture state badge
            if viewModel.captureState != .idle {
                captureStateBadge
            }
            
            Spacer()
            
            // Options button
            Button {
                showOptionsSheet = true
            } label: {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(isOptionsActive ? Color.primary : Color.icon)
                    .frame(width: 40, height: 40)
                    .background(
                        Circle()
                            .fill(Color.white.opacity(0.1))
                    )
                    .overlay(
                        Circle()
                            .strokeBorder(
                                isOptionsActive ? Color.primary.opacity(0.6) : Color.clear,
                                lineWidth: 2
                            )
                    )
                    .shadow(
                        color: isOptionsActive ? Color.primary.opacity(0.4) : .clear,
                        radius: 10,
                        x: 0,
                        y: 5
                    )
            }
            .matchedTransitionSource(id: "optionsSheet", in: sheetAnimation)
        }
    }
    
    // MARK: - Camera Preview
    
    @State private var focusIndicatorPosition: CGPoint? = nil
    
    private func cameraPreviewSection(proxy: GeometryProxy) -> some View {
        let previewWidth = proxy.size.width - 32
        let previewHeight = previewWidth * 1.2
        
        return ZStack {
            CameraPreviewView(
                session: viewModel.session,
                onFocusTap: { tapInfo in
                    // tapInfo contains properly converted device coordinates + original view coordinates
                    
                    // If currently locked, unlock first
                    if viewModel.isFocusLocked {
                        viewModel.dismissFocus()
                    }
                    
                    // Store the view position for indicator display (original tap location)
                    focusIndicatorPosition = tapInfo.viewPoint
                    
                    // Focus at the properly converted device coordinates
                    viewModel.focusAt(tapInfo.devicePoint)
                },
                onLongPress: { devicePoint in
                    // Long press - lock focus and exposure
                    let generator = UIImpactFeedbackGenerator(style: .medium)
                    generator.impactOccurred()
                    
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                        viewModel.lockFocusAndExposure()
                    }
                }
            )
            .frame(width: previewWidth, height: previewHeight)
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .strokeBorder(Color.white.opacity(0.08), lineWidth: 1)
            )
            
            // Grid overlay
            if viewModel.showGrid {
                GridOverlayView()
                    .frame(width: previewWidth, height: previewHeight)
                    .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                    .allowsHitTesting(false)
            }
            
            // Focus indicator with exposure control
            if viewModel.showFocusIndicator, let indicatorPos = focusIndicatorPosition {
                // Calculate clamped position to keep indicator within preview bounds
                let indicatorWidth: CGFloat = 120 // circle + slider width
                let indicatorHeight: CGFloat = 180 // slider height
                
                // Clamp X: circle is on left, slider on right
                let minX: CGFloat = 45 // half circle size
                let maxX = previewWidth - indicatorWidth + 45
                let clampedX = min(max(indicatorPos.x, minX), maxX)
                
                // Clamp Y
                let minY = indicatorHeight / 2
                let maxY = previewHeight - indicatorHeight / 2
                let clampedY = min(max(indicatorPos.y, minY), maxY)
                
                FocusIndicatorView(
                    isLocked: viewModel.isFocusLocked,
                    exposureBias: $viewModel.focusExposureBias,
                    onExposureChange: { bias in
                        viewModel.cancelFocusHide()
                        viewModel.adjustExposure(bias)
                    },
                    onDragEnded: {
                        if !viewModel.isFocusLocked {
                            viewModel.scheduleFocusHide()
                        }
                    }
                )
                .position(x: clampedX, y: clampedY)
                .allowsHitTesting(true)
            }
            
            // Overlays on camera
            VStack {
                HStack {
                    // AE/AF Lock badge
                    if viewModel.isFocusLocked {
                        HStack(spacing: 4) {
                            Image(systemName: "lock.fill")
                                .font(.system(size: 10, weight: .bold))
                            Text("AE/AF LOCK")
                                .font(.system(size: 10, weight: .bold))
                        }
                        .foregroundStyle(.black)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.gold)
                        .clipShape(Capsule())
                        .transition(.scale.combined(with: .opacity))
                    }
                    
                    Spacer()
                    lastCaptureThumbnail
                }
                
                Spacer()
                
                // Lens selector overlay at bottom of camera view
                ExpandableLensSelector(selectedLens: $viewModel.selectedLens)
                    .padding(.bottom, 12)
            }
            .padding(12)
            .allowsHitTesting(true)
        }
        .frame(width: previewWidth, height: previewHeight)
        .onChange(of: viewModel.showFocusIndicator) { showing in
            if !showing {
                focusIndicatorPosition = nil
            }
        }
    }
    
    // MARK: - Control Buttons Row
    
    private var controlButtonsRow: some View {
        HStack(spacing: 32) {
            // EV, Temperature, Shutter, ISO buttons (selectable)
            ForEach(CameraControlType.allCases) { controlType in
                CameraControlButton(
                    icon: controlType.icon,
                    isSelected: viewModel.activeControl == controlType,
                    isActive: isControlActive(controlType),
                    action: { viewModel.activeControl = controlType }
                )
            }
            
            // Filter button (opens sheet)
            CameraControlButton(
                icon: "circle.hexagongrid.fill",
                isSelected: false,
                isActive: viewModel.selectedFilter != .none,
                action: { showFilterSheet = true }
            )
            .matchedTransitionSource(id: "filter", in: filterNameSpace)
        }
    }
    
    /// Check if a control has been manually set (not in auto mode)
    private func isControlActive(_ controlType: CameraControlType) -> Bool {
        switch controlType {
        case .exposure: return !viewModel.isExposureAuto
        case .temperature: return !viewModel.isTemperatureAuto
        case .shutterSpeed: return !viewModel.isShutterAuto
        case .iso: return !viewModel.isISOAuto
        }
    }
    
    /// Check if any option has been changed from default
    private var isOptionsActive: Bool {
        viewModel.showGrid || !viewModel.storeLocation || viewModel.whiteBalancePreset != .auto
    }
    
    // MARK: - Control Wheel Section
    
    private var controlWheelSection: some View {
        VStack(spacing: 12) {
            // Header with current control info
            CameraControlHeader(
                icon: viewModel.activeControl.icon,
                title: viewModel.activeControl.title,
                displayValue: viewModel.currentDisplayValue,
                isAuto: viewModel.currentAutoState,
                onAutoToggle: { viewModel.toggleAutoForCurrentControl() }
            )
            
            // Wheel
            CameraControlWheel(
                value: viewModel.currentControlValue,
                range: viewModel.activeControl.range,
                step: viewModel.activeControl.step,
                defaultValue: viewModel.activeControl.defaultValue,
                isAuto: viewModel.currentAutoState,
                onScrollStarted: { viewModel.disableAutoForCurrentControl() }
            )
        }
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.white.opacity(0.06))
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.08), lineWidth: 1)
                )
        )
    }
    
    // MARK: - Capture Button
    
    private var captureButton: some View {
        Button {
            locationService.refreshLocation()
            viewModel.capture(
                modelContext: modelContext,
                locationDescription: locationService.locationDescription
            )
        } label: {
            Image(systemName: "camera.fill")
                .font(.system(size: 24, weight: .medium))
                .foregroundStyle(.white)
                .frame(width: 72, height: 48)
                .background(
                    Capsule()
                        .fill(Color.primary)
                )
                .overlay(
                    Capsule()
                        .strokeBorder(Color.primary.opacity(0.3), lineWidth: 2)
                        .padding(-4)
                )
        }
        .disabled(viewModel.captureState == .capturing || viewModel.captureState == .processing)
        .opacity(viewModel.captureState == .capturing || viewModel.captureState == .processing ? 0.5 : 1.0)
        .accessibilityLabel("Capture photo")
        .accessibilityHint("Shoots using the current lens, filter and exposure settings")
    }
    
    // MARK: - Capture State Badge
    
    private var captureStateBadge: some View {
        Group {
            switch viewModel.captureState {
            case .capturing:
                Label("Capturing…", systemImage: "camera.aperture")
            case .processing:
                Label("Processing…", systemImage: "gearshape.2")
            case .saved:
                Label("Saved", systemImage: "checkmark.circle")
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                            withAnimation {
                                viewModel.resetStatus()
                            }
                        }
                    }
            case .failure(let message):
                Label(message, systemImage: "exclamationmark.triangle")
            default:
                EmptyView()
            }
        }
        .font(.caption)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            Capsule(style: .continuous)
                .fill(Color.black.opacity(0.6))
        )
        .foregroundStyle(.white)
    }
    
    // MARK: - Last Capture Thumbnail
    
    private var lastCaptureThumbnail: some View {
        Group {
            if let asset = viewModel.lastSavedAsset,
               let image = PhotoImageProvider.image(at: asset.thumbnailURL) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 56, height: 56)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .strokeBorder(Color.white.opacity(0.2), lineWidth: 1)
                    )
            }
        }
    }
}

// MARK: - Focus Indicator View (Apple Camera Style)

struct FocusIndicatorView: View {
    let isLocked: Bool
    @Binding var exposureBias: Float
    let onExposureChange: (Float) -> Void
    let onDragEnded: () -> Void
    
    @State private var scale: CGFloat = 1.4
    @State private var opacity: Double = 0.0
    @State private var isDraggingExposure: Bool = false
    @State private var dragStartY: CGFloat = 0
    @State private var initialBias: Float = 0
    
    private let circleSize: CGFloat = 75
    private let sliderHeight: CGFloat = 150
    
    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            // Focus circle
            ZStack {
                // Outer circle
                Circle()
                    .strokeBorder(
                        isLocked ? Color.gold : Color.gold,
                        lineWidth: isLocked ? 2 : 1.5
                    )
                    .frame(width: circleSize, height: circleSize)
                
                // Inner crosshairs (subtle)
                if !isLocked {
                    Group {
                        Rectangle()
                            .fill(Color.gold.opacity(0.6))
                            .frame(width: 1, height: 15)
                        Rectangle()
                            .fill(Color.gold.opacity(0.6))
                            .frame(width: 15, height: 1)
                    }
                }
                
                // Lock icon when locked
                if isLocked {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Color.gold)
                }
            }
            
            // Exposure slider (always visible)
            VStack(spacing: 4) {
                // Plus indicator
                Image(systemName: "plus")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(Color.gold.opacity(0.7))
                
                // Slider track
                ZStack(alignment: .center) {
                    // Track background
                    Capsule()
                        .fill(Color.white.opacity(0.2))
                        .frame(width: 3, height: sliderHeight)
                    
                    // Center marker
                    Circle()
                        .fill(Color.white.opacity(0.5))
                        .frame(width: 5, height: 5)
                    
                    // Sun indicator (draggable)
                    Image(systemName: "sun.max.fill")
                        .font(.system(size: 18))
                        .foregroundStyle(Color.gold)
                        .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
                        .offset(y: CGFloat(-exposureBias) * (sliderHeight / 6)) // Map -3...3 to slider
                }
                .frame(height: sliderHeight)
                .contentShape(Rectangle().size(width: 44, height: sliderHeight + 20))
                .gesture(
                    DragGesture(minimumDistance: 1)
                        .onChanged { value in
                            if !isDraggingExposure {
                                isDraggingExposure = true
                                dragStartY = value.startLocation.y
                                initialBias = exposureBias
                            }
                            
                            let deltaY = dragStartY - value.location.y
                            let biasChange = Float(deltaY / (sliderHeight / 6))
                            let newBias = min(max(initialBias + biasChange, -3.0), 3.0)
                            onExposureChange(newBias)
                        }
                        .onEnded { _ in
                            isDraggingExposure = false
                            onDragEnded()
                        }
                )
                
                // Minus indicator
                Image(systemName: "minus")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(Color.gold.opacity(0.7))
            }
        }
        .scaleEffect(scale)
        .opacity(opacity)
        .onAppear {
            withAnimation(.spring(response: 0.25, dampingFraction: 0.65)) {
                scale = 1.0
                opacity = 1.0
            }
        }
        .onChange(of: isLocked) { locked in
            if locked {
                // Pulse animation when locking
                withAnimation(.spring(response: 0.2, dampingFraction: 0.5)) {
                    scale = 1.08
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                    withAnimation(.spring(response: 0.2, dampingFraction: 0.7)) {
                        scale = 1.0
                    }
                }
            }
        }
    }
}

#Preview {
    CameraView(isActive: true)
        .environmentObject(LocationService())
        .modelContainer(for: PhotoAsset.self, inMemory: true)
}
