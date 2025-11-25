//
//  CameraView.swift
//  Blinky
//
//  Created by Codex.
//

import SwiftUI
import SwiftData

struct CameraView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var locationService: LocationService
    @StateObject private var viewModel = CameraViewModel()
    let isActive: Bool
    
    @State private var showFilterSheet = false
    @State private var showOptionsSheet = false
    
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
                FilterSheetView(selectedFilter: $viewModel.selectedFilter)
            }
            .sheet(isPresented: $showOptionsSheet) {
                CameraOptionsSheet(
                    storeLocation: $viewModel.storeLocation,
                    showGrid: $viewModel.showGrid,
                    whiteBalancePreset: $viewModel.whiteBalancePreset
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
                    .foregroundStyle(Color.icon)
                    .frame(width: 40, height: 40)
                    .background(
                        Circle()
                            .fill(Color.white.opacity(0.1))
                    )
            }
        }
    }
    
    // MARK: - Camera Preview
    
    private func cameraPreviewSection(proxy: GeometryProxy) -> some View {
        let previewWidth = proxy.size.width - 32
        let previewHeight = previewWidth * 1.2
        
        return ZStack {
            CameraPreviewView(session: viewModel.session)
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
            }
            
            // Overlays on camera
            VStack {
                HStack {
                    Spacer()
                    lastCaptureThumbnail
                }
                
                Spacer()
                
                // Lens selector overlay at bottom of camera view
                ExpandableLensSelector(selectedLens: $viewModel.selectedLens)
                    .padding(.bottom, 12)
            }
            .padding(12)
        }
        .frame(width: previewWidth, height: previewHeight)
    }
    
    // MARK: - Control Buttons Row
    
    private var controlButtonsRow: some View {
        HStack(spacing: 32) {
            // EV, Temperature, Shutter, ISO buttons (selectable)
            ForEach(CameraControlType.allCases) { controlType in
                CameraControlButton(
                    icon: controlType.icon,
                    isSelected: viewModel.activeControl == controlType,
                    action: { viewModel.activeControl = controlType }
                )
            }
            
            // Filter button (opens sheet)
            CameraControlButton(
                icon: "circle.hexagongrid.fill",
                isSelected: false,
                action: { showFilterSheet = true }
            )
        }
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

#Preview {
    CameraView(isActive: true)
        .environmentObject(LocationService())
        .modelContainer(for: PhotoAsset.self, inMemory: true)
}
