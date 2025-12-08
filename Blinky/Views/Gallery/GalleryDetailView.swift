//
//  GalleryDetailView.swift
//  Blinky
//
//  Created by Codex.
//

import SwiftUI
import SwiftData

struct GalleryDetailView: View {
    let asset: PhotoAsset
    let assets: [PhotoAsset]  // Pass assets directly instead of using @Query
    let galleryNamespace: Namespace.ID
    let onDelete: () -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var isPresenting: Bool = false
    @State private var currentAssetId: PhotoAsset.ID?
    @State private var allowDismissalGesture: AllowedNavigationDismissalGestures = .none
    
    /// The currently displayed asset based on scroll position
    private var currentAsset: PhotoAsset {
        if let id = currentAssetId, let foundAsset = assets.first(where: { $0.id == id }) {
            return foundAsset
        }
        return asset
    }
    
    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size
            ZStack {
                // Content
                VStack(spacing: 0) {
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 24) {
                            headerCarousel(size: size)
                            
                                infoSection()
                                    .padding(16)
                                    .cornerRadius(32)
                                    .glassEffect(
                                        .clear.interactive(),
                                        in: .rect(cornerRadius: 32)
                                    )
                                    .padding(.horizontal, 16)
                                    .animation(.easeInOut(duration: 0.3), value: currentAssetId)
 
                        }
                        .padding(.bottom, 100) // Space for bottom bar
                    }
                }
                
                // Bottom Action Bar
                bottomBar()
            }
            .navigationBarBackButtonHidden(true)
            .toolbar(.hidden, for: .navigationBar)
            
            // Dynamic sourceID based on currently viewed asset
            .navigationTransition(
                .zoom(
                    sourceID: isPresenting ? (currentAssetId ?? asset.id) : asset.id,
                    in: galleryNamespace
                )
            )
            .background {
                // Blurred Background Image
                AsyncPhotoImage(url: currentAsset.originalURL, contentMode: .fill)
                    .id(currentAsset.id) // Force view recreation when asset changes
                    .blur(radius: 50)
                    .scaleEffect(1.3)
                    .overlay(Color.black.opacity(0.4))
                    .ignoresSafeArea()
                    .transition(.opacity.animation(.easeInOut(duration: 0.4)))
                    .animation(.easeInOut(duration: 0.4), value: currentAssetId)
            }
            .onChange(of: currentAssetId) { oldId, newId in
                print("Background should change: \(String(describing: oldId)) -> \(String(describing: newId))")
            }
            .navigationAllowDismissalGestures(allowDismissalGesture)
            .task {
                Task {
                    try? await Task.sleep(for: .seconds(1))
                    allowDismissalGesture = .all
                }
            }
        }
    }
    
    // MARK: - Sections
    
    @ViewBuilder
    private func headerCarousel(size: CGSize) -> some View {
        ZStack {
            ScrollView(.horizontal) {
                LazyHStack(spacing: 24) {
                    ForEach(assets) { item in
                        AsyncPhotoImage(url: item.originalURL, contentMode: .fit)
                            .clipShape(RoundedRectangle(cornerRadius: 24))
                            .gyroscope3D(intensity: 0.3, perspective: 0.3)
                            
                            .shadow(color: Color.black.opacity(0.3), radius: 8, x: 0, y: 4)
                            .containerRelativeFrame(.horizontal, count: 1, span: 1, spacing: 8)
                            .scaledToFill()
                            .frame(height: CGFloat(size.height / 1.8))
                            
                            .padding(.top, 8)
                            .padding(.bottom, 16)
                    }
                }
                .scrollTargetLayout()
            }
            
            .scrollTargetBehavior(.viewAligned)
            .scrollIndicators(.hidden)
            .scrollPosition(id: $currentAssetId)
            .onAppear {
                // Scroll to the initially selected asset
                currentAssetId = asset.id
            }
//            .padding(.horizontal, 16)
            .zIndex(1)
            
            if !isPresenting {
                AsyncPhotoImage(url: asset.originalURL, contentMode: .fit)
                    .scaledToFit()
                    .frame(height: CGFloat(size.height / 2))
                    .shadow(color: Color.black.opacity(0.3), radius: 8, x: 0, y: 4)
                    .padding(.top, 8)
                    .task {
                        currentAssetId = asset.id
                        try? await Task.sleep(for: .seconds(0.15))
                        isPresenting = true
                    }
            }
        }
    }
    
    @ViewBuilder
    private func infoSection() -> some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header Info
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(currentAsset.filterName.isEmpty ? "Original" : currentAsset.filterName)
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(.black)
                        .contentTransition(.numericText())
                    
                    Text(dateFormatter.string(from: currentAsset.capturedAt))
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.blackKite)
                        .contentTransition(.numericText())
                }
                
                Spacer()
                
                Button(action: {}) {
                    Text("Use this Filter")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.blackKite)
                        .cornerRadius(24)
                }
            }
            
            Divider()
                .background(Color.secondaryBackground)
            
            // Camera Details Grid
            LazyVGrid(columns: gridColumns, spacing: 8) {
                detailItem(icon: "camera.aperture", title: "Aperture", value: "f/\(String(format: "%.1f", currentAsset.aperture))")
                detailItem(icon: "shutter", title: "Shutter", value: currentAsset.shutterSpeed)
                detailItem(icon: "sun.max", title: "ISO", value: "\(Int(currentAsset.iso))")
                detailItem(icon: "timelapse", title: "Lens", value: currentAsset.lens)
            }
            
            if let location = currentAsset.locationDescription {
                Divider()
                    .background(Color.black)
                
                HStack(spacing: 12) {
                    Image(systemName: "mappin.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.blackKite)
                    
                    Text(location)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.blackKite)
                        .contentTransition(.numericText())
                    
                    Spacer()
                }
                .padding(.vertical, 4)
            }
        }
    }
    
    @ViewBuilder
    private func bottomBar() -> some View {
        VStack {
            Spacer()
            HStack(spacing: 40) {
                actionButton(icon: "folder", action: {})
                
                // Main Action (e.g. Edit or Favorite) - Central Button
                Button(action: {}) {
                    Image(systemName: "heart.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.white)
                        .frame(width: 52, height: 52)
                        .background(Color.primary)
                        .clipShape(Circle())
                        .shadow(color: Color.primary.opacity(0.4), radius: 10, x: 0, y: 5)
                }
                
                actionButton(icon: "trash", action: {
                    onDelete()
                    dismiss()
                }, isDestructive: true)
            }
            .padding(.horizontal, 30)
            .padding(.bottom, 0)
        }
    }
    
    // MARK: - Helpers
    
    private let gridColumns: [GridItem] = [GridItem(.flexible()), GridItem(.flexible())]
    
    private func detailItem(icon: String, title: String, value: String) -> some View {
        HStack(spacing: 12) {
            // Check if it's a custom asset icon or system icon
            Group {
                if icon == "shutter" {
                    Image(icon)
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .foregroundColor(.white)
                        .frame(width: 18, height: 18)
                        
                } else {
                    Image(systemName: icon)
                        .font(.system(size: 18))
                }
            }
            .foregroundColor(.white)
            .frame(width: 32, height: 32)
            .background(Color.secondaryBackground)
            .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.black)
                Text(value)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.blackKite)
                    .contentTransition(.numericText())
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private func actionButton(icon: String, action: @escaping () -> Void, isDestructive: Bool = false) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(isDestructive ? .red : .icon)
                .padding(16)
        }
    }
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM dd, yyyy"
        return formatter
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
