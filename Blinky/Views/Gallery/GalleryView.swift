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
    let namespace: Namespace.ID
    
    
    init(focusedAsset: Binding<PhotoAsset?>, namespace: Namespace.ID) {
        self._focusedAsset = focusedAsset
        self.namespace = namespace
    }
    
    
    var body: some View {
        NavigationView{
            ZStack {
                Color.blackKite.ignoresSafeArea()

                VStack(alignment: .leading, spacing: 16){
                    ScrollView(showsIndicators: false) {
                        galleryGrid
                            
                    }
                    .scrollClipDisabled(false)
                    .navigationDestination(for: PhotoAsset.self) { asset in
                        GalleryDetailView(
                            asset: asset,
                            namespace: namespace,
                            onDelete: {}
                        )
                    }
                }

                
               
               
//                .clipShape(Rectangle())
//                .toolbarBackground(.hidden, for: .navigationBar)
                
              
                //Hover
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
            } .toolbar {
                if viewModel.isSelectionMode {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Delete", systemImage: "trash") {
                            if !viewModel.selectedAssetIDs.isEmpty {
                                withAnimation {
                                    viewModel.deleteSelected(from: assets, context: modelContext)
                                }
                            }
                        }
                        .tint(viewModel.selectedAssetIDs.isEmpty ? .secondary : .red)
                        .disabled(viewModel.selectedAssetIDs.isEmpty)
                    }
                }
                ToolbarSpacer(.fixed, placement: .topBarTrailing)
                
                ToolbarItem(placement: .topBarTrailing) {
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
                            .foregroundColor(Color.text)
                    }
                }
            }
        }
            

            .edgesIgnoringSafeArea(.bottom)
            .edgesIgnoringSafeArea(.top)

        }
       
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM. yyyy"
        return formatter.string(from: Date())
    }
    
    private var galleryGrid: some View {
        
        return Masonry(.vertical, lines: 2) {
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
                // Apply matchedGeometryEffect to just the image
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
                    .shadow(
                        color: Color(.sRGB, red: 245/255, green: 245/255, blue: 237/255, opacity: 0.15),
                        radius: 8,
                        x: 2,
                        y: 2
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
        GalleryView(focusedAsset: $focusedAsset, namespace: namespace)
            .modelContainer(container)
    }
}
