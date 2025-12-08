//
//  GalleryView.swift
//  Blinky
//
//  Created by Codex.
//

import SwiftUI
import SwiftData
import UIKit
import SwiftUIMasonry

struct GalleryView: View {
    @Binding var focusedAsset: PhotoAsset?
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \PhotoAsset.capturedAt, order: .reverse) private var assets: [PhotoAsset]
    @State private var hoveredAsset: PhotoAsset?
    @StateObject private var viewModel = GalleryViewModel()
    @State private var isScrolledPastTop: Bool = false
    @Namespace private var namespaceHeader
    @Binding var isScrolledToBottom: Bool
    let safeArea: EdgeInsets
    let galleryNamespace: Namespace.ID
    @State var isMatchedGeometryPresented = false
  
    
    init(focusedAsset: Binding<PhotoAsset?>, isScrolledToBottom: Binding<Bool>, safeArea: EdgeInsets, galleryNamespace: Namespace.ID) {
        self._focusedAsset = focusedAsset
        self._isScrolledToBottom = isScrolledToBottom
        self.safeArea = safeArea
        self.galleryNamespace = galleryNamespace
    }
    
    
    var body: some View {
        ZStack(alignment: .top) {
            Color.background.ignoresSafeArea()
            
            // ScrollView content
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    // Spacer for header
                    Color.clear.frame(height: safeArea.top + 52)
                    
                    galleryGrid
                    
                    // Bottom spacer for tab bar
                    Color.clear.frame(height: safeArea.bottom + 80)
                }
            }
            .scrollClipDisabled(false)
            .onScrollGeometryChange(for: Bool.self) { geometry in
                geometry.contentOffset.y > 0
            } action: { _, isPastTop in
                withAnimation(.easeInOut(duration: 0.2)) {
                    isScrolledPastTop = isPastTop
                }
            }
            .onScrollGeometryChange(for: Bool.self) { geometry in
                // Check if not at the very bottom
                let maxOffset = geometry.contentSize.height - geometry.containerSize.height
                return geometry.contentOffset.y < maxOffset - 10
            } action: { _, notAtBottom in
                withAnimation(.easeInOut(duration: 0.2)) {
                    isScrolledToBottom = notAtBottom
                }
            }
            
            // Custom Header
            ScrollableHeader(
                safeAreaTop: safeArea.top,
                isScrolled: isScrolledPastTop
            ) {
                if viewModel.isSelectionMode {
                    Button {
                        if !viewModel.selectedAssetIDs.isEmpty {
                            withAnimation {
                                viewModel.deleteSelected(from: assets, context: modelContext)
                            }
                        }
                    } label: {
                        Image(systemName: "trash")
                            .font(.system(size: 16, weight: .medium))
                            .frame(width: 42, height: 42)
                            .glassEffect()
                            .glassEffectID("trash", in: namespaceHeader)
                            .foregroundColor(viewModel.selectedAssetIDs.isEmpty ? .secondary : .red)
                    }
                    .disabled(viewModel.selectedAssetIDs.isEmpty)
                }
                
                Button {
                    withAnimation {
                        viewModel.toggleSelectionMode()
                        if !viewModel.isSelectionMode {
                            focusedAsset = nil
                        }
                    }
                } label: {
                    Text(viewModel.isSelectionMode ? "Done" : "Select")
                        .font(.system(size: 16, weight: .medium))
                        .frame(minWidth: 64, minHeight: 42)
                        .foregroundColor(Color.text)
                        .glassEffect()
                        .glassEffectID("select", in: namespaceHeader)
                }
            }
            
            // Hover
            if let asset = hoveredAsset {
                HoverView(
                    asset: asset,
                    onClose: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            hoveredAsset = nil
                        }
                    },
                    onDelete: {
                        withAnimation {
                            viewModel.delete(asset, context: modelContext)
                            hoveredAsset = nil
                        }
                    }
                )
                .zIndex(2)
            }
        }
  
        .navigationDestination(for: PhotoAsset.self) { selectedAsset in
            GalleryDetailView(
                asset: selectedAsset,
                assets: assets,
                galleryNamespace: galleryNamespace,
                onDelete: {
                    withAnimation {
                        viewModel.delete(selectedAsset, context: modelContext)
                    }
                }
            )
            
        }
    }
       
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM. yyyy"
        return formatter.string(from: Date())
    }
    
    private var galleryGrid: some View {
        
        return Masonry(.vertical, lines: 2, spacing: 16) {
            ForEach(assets){ asset in
                let isFocused = focusedAsset?.id == asset.id
                let isHovered = hoveredAsset?.id == asset.id
                
                GalleryTileWithNavigation(
                    asset: asset,
                    assets: assets,
                    isSelectionMode: viewModel.isSelectionMode,
                    isSelected: viewModel.isSelected(asset),
                    isFocused: isFocused || isHovered,
                    galleryNamespace: galleryNamespace,
                    onDelete: {
                        withAnimation {
                            viewModel.delete(asset, context: modelContext)
                            if focusedAsset?.id == asset.id {
                                focusedAsset = nil
                            }
                        }
                    },
                    onLongPress: {
                        if !viewModel.isSelectionMode {
                            withAnimation(.linear(duration: 0.2)) {
                                hoveredAsset = asset
                            }
                        }
                    },
                    onSelectionTap: {
                        viewModel.toggleSelection(for: asset)
                    }
                )
            }
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 24)
    }
}

// Separate view to handle navigation per tile
private struct GalleryTileWithNavigation: View {
    let asset: PhotoAsset
    let assets: [PhotoAsset]
    let isSelectionMode: Bool
    let isSelected: Bool
    let isFocused: Bool
    let galleryNamespace: Namespace.ID
    let onDelete: () -> Void
    let onLongPress: () -> Void
    let onSelectionTap: () -> Void
    
    @Environment(\.modelContext) private var modelContext
    
    var body: some View {
        ZStack {
            NavigationLink(value: asset) {
                GalleryTile(
                    asset: asset,
                    isSelectionMode: isSelectionMode,
                    isSelected: isSelected,
                    isFocused: isFocused,
                    isPresenting: false,
                    onDelete: onDelete
                )
            }
            .buttonStyle(ScaleButtonStyle())
            .matchedTransitionSource(id: asset.id, in: galleryNamespace)
            .disabled(isSelectionMode)
            .simultaneousGesture(
                LongPressGesture(minimumDuration: 0.5)
                    .onEnded { _ in
                        onLongPress()
                    }
            )
            
            // Overlay button for selection mode
            if isSelectionMode {
                Color.clear
                    .contentShape(Rectangle())
                    .onTapGesture {
                        onSelectionTap()
                    }
            }
        }
    }
}


private struct GalleryTile: View {
    let asset: PhotoAsset
    let isSelectionMode: Bool
    let isSelected: Bool
    let isFocused: Bool
    let isPresenting: Bool
    let onDelete: () -> Void
    @State private var isPressed: Bool = false
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            // NOTE: SwiftUI's AsyncImage only works with NETWORK URLs
            // For local file URLs, we must use our custom AsyncPhotoImage
            AsyncPhotoImage(url: asset.thumbnailURL, contentMode: .fit)
            
                .opacity(isFocused || isPresenting ? 0 : 1)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 3)
                )
            
            if isSelectionMode {
                ZStack {
                    if isSelected {
                        Circle()
                            .fill(Color.blue)
                            .frame(width: 24, height: 24)
                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                    } else {
                        Circle()
                            .stroke(Color.white, lineWidth: 2)
                            .frame(width: 24, height: 24)
                            .background(Circle().fill(Color.black.opacity(0.3)))
                    }
                }
                .padding(8)
            }
        }
        .drawingGroup()
    }
    
    private func galleryHeight(for image: UIImage) -> CGFloat {
        let ratio = image.size.height / max(image.size.width, 1)
        let baseWidth: CGFloat = 112
        return max(112, min(ratio * baseWidth, 250))
    }
}

struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        return configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
            .animation(.linear(duration: 0.1), value: configuration.isPressed)
    }
}

#Preview {
    @Previewable @State var focusedAsset: PhotoAsset? = nil
    @Previewable @State var isScrolledToBottom = true
    @Previewable @Namespace var previewNamespace
    
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: PhotoAsset.self, configurations: config)
    
    // Create temporary files from asset catalog images
    let tempDir = FileManager.default.temporaryDirectory
    let imageNames = ["img1", "img2", "img3", "img4"]
    
    for (index, imageName) in imageNames.enumerated() {
        let imageURL = tempDir.appendingPathComponent("sample\(index + 1).jpg")
        
        // Write asset catalog image to temp file
        if let image = UIImage(named: imageName),
           let data = image.jpegData(compressionQuality: 0.9) {
            try? data.write(to: imageURL)
        }
        
        let asset = PhotoAsset(
            originalURL: imageURL,
            previewURL: imageURL,
            thumbnailURL: imageURL,
            filterName: ["Cinematic", "Vivid", "Noir", "Classic Film"][index],
            lens: ["50mm", "24mm", "33mm", "70mm"][index],
            iso: [400, 200, 800, 100][index],
            aperture: [1.8, 2.8, 1.4, 2.0][index],
            shutterSpeed: ["1/125", "1/250", "1/60", "1/500"][index],
            locationDescription: ["Tokyo, Japan", "New York, USA", "Paris, France", "London, UK"][index],
            capturedAt: Date().addingTimeInterval(Double(-86400 * (index + 1)))
        )
        container.mainContext.insert(asset)
    }
    
    return NavigationStack {
        GalleryView(
            focusedAsset: $focusedAsset,
            isScrolledToBottom: $isScrolledToBottom,
            safeArea: EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0),
            galleryNamespace: previewNamespace
        )
    }
    .modelContainer(container)
}
