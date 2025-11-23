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
    
    var body: some View {
        GeometryReader { proxy in
            let sheetHeight = max(proxy.size.height * 0.32, 280)
            ZStack {
                cameraPreview
                
                VStack(spacing: 18) {
                    Spacer()
                    captureControls
                    bottomSheet(height: sheetHeight)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 16)
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
            .background(Color.black)
            .navigationTitle("Camera")
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
    }
    
    private var cameraPreview: some View {
        ZStack(alignment: .topLeading) {
            CameraPreviewView(session: viewModel.session)
                .ignoresSafeArea()
                .overlay(alignment: .topTrailing) {
                    lastCaptureThumbnail
                        .padding(16)
                }
            captureStateBadge
                .padding(16)
        }
    }
    
    private func bottomSheet(height: CGFloat) -> some View {
        VStack(spacing: 16) {
            Capsule()
                .fill(Color.white.opacity(0.35))
                .frame(width: 56, height: 4)
                .padding(.top, 4)
            
            if let location = locationService.locationDescription {
                Label(location, systemImage: "location.fill")
                    .font(.footnote)
                    .foregroundColor(.white.opacity(0.75))
                    .padding(.bottom, 4)
            }
            
            settingsPanel
        }
        .padding(.horizontal, 12)
        .padding(.bottom, 12)
        .frame(maxWidth: .infinity)
        .frame(height: height, alignment: .top)
        .background(
            BlurView(style: .systemChromeMaterialDark)
                .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .stroke(Color.white.opacity(0.06), lineWidth: 1)
                )
                .ignoresSafeArea(edges: .bottom)
        )
    }
    
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
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            Capsule(style: .continuous)
                .fill(Color.black.opacity(0.45))
        )
        .foregroundStyle(.white)
    }
    
    private var settingsPanel: some View {
        VStack(alignment: .leading, spacing: 16) {
            settingsRow(title: "Lens") {
                Picker("Lens", selection: $viewModel.selectedLens) {
                    ForEach(LensProfile.allCases) { lens in
                        Text("\(lens.title) (\(lens.rawValue))")
                            .tag(lens)
                    }
                }
                .pickerStyle(.segmented)
            }
            
            settingsRow(title: "Filter") {
                Picker("Filter", selection: $viewModel.selectedFilter) {
                    ForEach(FilterLUT.allCases) { filter in
                        Text(filter.rawValue)
                            .tag(filter)
                    }
                }
                .pickerStyle(.menu)
            }
            
            settingsRow(title: "ISO \(Int(viewModel.isoValue))") {
                Slider(value: $viewModel.isoValue, in: 100...1600, step: 50)
            }
            
            settingsRow(title: "Aperture f/\(String(format: "%.1f", viewModel.aperture))") {
                Slider(value: $viewModel.aperture, in: 1.4...4.0, step: 0.1)
            }
            
            settingsRow(title: "Shutter \(viewModel.shutterSpeed.rawValue)s") {
                Picker("Shutter", selection: $viewModel.shutterSpeed) {
                    ForEach(ShutterSpeedOption.allCases) { option in
                        Text(option.rawValue)
                            .tag(option)
                    }
                }
                .pickerStyle(.segmented)
            }
        }
    }
    
    private func settingsRow<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption)
                .foregroundColor(.white.opacity(0.6))
            content()
        }
    }
    
    private var captureControls: some View {
        HStack(spacing: 24) {
            Button {
                viewModel.resetStatus()
            } label: {
                Image(systemName: "slider.horizontal.3")
                    .font(.title3)
                    .frame(width: 52, height: 52)
                    .background(Circle().fill(Color.white.opacity(0.18)))
            }
            
            Button {
                locationService.refreshLocation()
                viewModel.capture(
                    modelContext: modelContext,
                    locationDescription: locationService.locationDescription
                )
            } label: {
                Circle()
                    .strokeBorder(Color.white.opacity(0.7), lineWidth: 4)
                    .frame(width: 104, height: 104)
                    .overlay(
                        Circle()
                            .fill(Color.red)
                            .frame(width: 74, height: 74)
                    )
            }
            .disabled(viewModel.captureState == .capturing || viewModel.captureState == .processing)
            .accessibilityLabel("Capture photo")
            .accessibilityHint("Shoots using the current lens, filter and exposure settings")
            
            Button {
                // placeholder for switching camera/back
            } label: {
                Image(systemName: "arrow.triangle.2.circlepath.camera")
                    .font(.title3)
                    .frame(width: 52, height: 52)
                    .background(Circle().fill(Color.white.opacity(0.18)))
            }
        }
        .foregroundColor(.white)
    }
    
    private var lastCaptureThumbnail: some View {
        Group {
            if let asset = viewModel.lastSavedAsset,
               let image = PhotoImageProvider.image(at: asset.thumbnailURL) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 96, height: 96)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .padding(12)
            }
        }
    }
}
