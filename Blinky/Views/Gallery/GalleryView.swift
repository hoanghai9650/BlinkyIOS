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
    let namespace: Namespace.ID
    @Namespace private var namespaceHeader
    @Binding var isScrolledToBottom: Bool
    let safeArea: EdgeInsets
    
    init(focusedAsset: Binding<PhotoAsset?>, namespace: Namespace.ID, isScrolledToBottom: Binding<Bool>, safeArea: EdgeInsets) {
        self._focusedAsset = focusedAsset
        self.namespace = namespace
        self._isScrolledToBottom = isScrolledToBottom
        self.safeArea = safeArea
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
                    namespace: namespace,
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
                
                ZStack {
                    NavigationLink(value: asset){
                        GalleryTile(
                            asset: asset,
                            isSelectionMode: viewModel.isSelectionMode,
                            isSelected: viewModel.isSelected(asset),
                            isFocused: isFocused || isHovered,
                            namespace: namespace,
                            onDelete: {
                                withAnimation {
                                    viewModel.delete(asset, context: modelContext)
                                    if focusedAsset?.id == asset.id {
                                        focusedAsset = nil
                                    }
                                }
                            }
                        )
                        .matchedTransitionSource(id: asset.id, in: namespace){
                            $0.background(.clear)
                                .clipShape(.rect(cornerRadius: 16))
                        }
                    }
                    .disabled(viewModel.isSelectionMode)
                    .simultaneousGesture(
                        LongPressGesture(minimumDuration: 0.5)
                            .onEnded { _ in
                                if !viewModel.isSelectionMode {
                                    withAnimation(.linear(duration: 0.2)) {
                                        hoveredAsset = asset
                                    }
                                }
                            }
                    )
                    
                    // Overlay button for selection mode
                    if viewModel.isSelectionMode {
                        Color.clear
                            .contentShape(Rectangle())
                            .onTapGesture {
                                viewModel.toggleSelection(for: asset)
                            }
                    }
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 24)
    }
}


private struct GalleryTile: View {
    let asset: PhotoAsset
    let isSelectionMode: Bool
    let isSelected: Bool
    let isFocused: Bool
    let namespace: Namespace.ID
    let onDelete: () -> Void
    @State private var isPressed: Bool = false
    
    var body: some View {
        // Use previewURL for consistent image quality with detail view
        let image = PhotoImageProvider.image(at: asset.originalURL)
        return ZStack(alignment: .topTrailing) {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .matchedGeometryEffect(
                        id: asset.id,
                        in: namespace,
                        isSource: true
                    )
                    .scaledToFill()
                    .opacity(isFocused ? 0 : 1)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 3)
                    )
            } else {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.gray.opacity(0.25))
                    .matchedGeometryEffect(
                        id: asset.id,
                        in: namespace,
                        isSource: true
                    )
            }
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
    @Previewable @Namespace var namespace
    
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: PhotoAsset.self, configurations: config)
    
    // Add sample data
    let sampleAssets = [
        PhotoAsset(
            originalURL: URL(fileURLWithPath: "/tmp/sample1.jpg"),
            previewURL: URL(fileURLWithPath: "/tmp/sample1.jpg"),
            thumbnailURL: URL(fileURLWithPath: "/tmp/sample1.jpg"),
            filterName: "Cinematic",
            lens: "50mm",
            iso: 400,
            aperture: 1.8,
            shutterSpeed: "1/125",
            locationDescription: "Tokyo, Japan",
            capturedAt: Date().addingTimeInterval(-86400)
        ),
        PhotoAsset(
            originalURL: URL(fileURLWithPath: "/tmp/sample2.jpg"),
            previewURL: URL(fileURLWithPath: "/tmp/sample2.jpg"),
            thumbnailURL: URL(fileURLWithPath: "/tmp/sample2.jpg"),
            filterName: "Vivid",
            lens: "24mm",
            iso: 200,
            aperture: 2.8,
            shutterSpeed: "1/250",
            locationDescription: "New York, USA",
            capturedAt: Date().addingTimeInterval(-172800)
        ),
        PhotoAsset(
            originalURL: URL(fileURLWithPath: "/tmp/sample3.jpg"),
            previewURL: URL(fileURLWithPath: "/tmp/sample3.jpg"),
            thumbnailURL: URL(fileURLWithPath: "/tmp/sample3.jpg"),
            filterName: "Noir",
            lens: "33mm",
            iso: 800,
            aperture: 1.4,
            shutterSpeed: "1/60",
            locationDescription: "Paris, France",
            capturedAt: Date().addingTimeInterval(-259200)
        ),
        PhotoAsset(
            originalURL: URL(fileURLWithPath: "/tmp/sample4.jpg"),
            previewURL: URL(fileURLWithPath: "/tmp/sample4.jpg"),
            thumbnailURL: URL(fileURLWithPath: "/tmp/sample4.jpg"),
            filterName: "Classic Film",
            lens: "70mm",
            iso: 100,
            aperture: 2.0,
            shutterSpeed: "1/500",
            locationDescription: "London, UK",
            capturedAt: Date().addingTimeInterval(-345600)
        )
    ]
    
    for asset in sampleAssets {
        container.mainContext.insert(asset)
    }
    
    return NavigationStack {
        GalleryView(
            focusedAsset: $focusedAsset,
            namespace: namespace,
            isScrolledToBottom: $isScrolledToBottom,
            safeArea: EdgeInsets(top: 59, leading: 0, bottom: 34, trailing: 0)
        )
        .modelContainer(container)
    }
}
