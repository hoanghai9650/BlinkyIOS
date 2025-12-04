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
    let namespace: Namespace.ID
    let onDelete: () -> Void
    @Environment(\.dismiss) var dismiss
    @State private var allowDismissalGesture: AllowedNavigationDismissalGestures = .none
    
    var body: some View {
        
            ZStack {
                // Background
                Color.background.ignoresSafeArea()
                
                //Content
                VStack(spacing: 0) {
                    // Top Bar
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 24) {
                            // Destination Image
                            if let image = PhotoImageProvider.image(at: asset.originalURL) {
                                let aspectRatio = image.size.width / image.size.height
                                
                                Image(uiImage: image)
                                    .resizable()
                                    .aspectRatio(aspectRatio, contentMode: .fit)
                                    .frame(maxWidth: .infinity)
                                    .navigationTransition(.zoom(sourceID: asset.id, in: namespace))
                                    .shadow(color: Color.black.opacity(0.3), radius: 20, x: 0, y: 10)
//                                    .padding(.top, 32)
                                    .navigationAllowDismissalGestures(allowDismissalGesture)
                                    .task {
                                        Task {
                                            try? await Task.sleep(for: .seconds(1))
                                            allowDismissalGesture = .all
                                        }
                                    }
                                   
                            }
                            
                            // Info Section
                            GlassEffectContainer(){
                                VStack(alignment: .leading, spacing: 20) {
                                    // Header Info
                                    HStack(alignment: .top) {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(asset.filterName.isEmpty ? "Original" : asset.filterName)
                                                .font(.system(size: 24, weight: .bold))
                                                .foregroundColor(.black)
                                            
                                            Text(dateFormatter.string(from: asset.capturedAt))
                                                .font(.system(size: 14, weight: .medium))
                                                .foregroundColor(.blackKite)
                                        }
                                        
                                        Spacer()
                                        
                                        Button(action: {}) {
                                            Text("Use this Filter")
                                                .font(.system(size: 16, weight: .semibold))
                                                .foregroundColor(.white)
                                                .padding(.horizontal, 20)
                                                .padding(.vertical, 10)
                                                .background(Color.blackKite)
                                                .cornerRadius(24)
                                        }
                                    }
                                    
                                    Divider()
                                        .background(Color.secondaryBackground)
                                    
                                    // Camera Details Grid
                                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 20) {
                                        detailItem(icon: "camera.aperture", title: "Aperture", value: "f/\(String(format: "%.1f", asset.aperture))")
                                        detailItem(icon: "shutter", title: "Shutter", value: asset.shutterSpeed)
                                        detailItem(icon: "sun.max", title: "ISO", value: "\(Int(asset.iso))")
                                        detailItem(icon: "camera.lens", title: "Lens", value: asset.lens)
                                    }
                                    
                                    if let location = asset.locationDescription {
                                        Divider()
                                            .background(Color.black)
                                        
                                        HStack(spacing: 12) {
                                            Image(systemName: "mappin.circle.fill")
                                                .font(.system(size: 20))
                                                .foregroundColor(.blackKite)
                                            
                                            Text(location)
                                                .font(.system(size: 14, weight: .medium))
                                                .foregroundColor(.blackKite)
                                            
                                            Spacer()
                                        }
                                        .padding(.vertical, 4)
                                    }
                                }
                                .padding(24)
                                .background(Color.primary)
                                .cornerRadius(32)
                                .glassEffect(
                                    .regular.interactive(),
                                    in: .rect(cornerRadius: 32)
                                )
                                .padding(.horizontal, 16)
                            }
                        }
                        .padding(.bottom, 100) // Space for bottom bar
                    }
                }
//                .toolbar{
//                    ToolbarItem(placement: .cancellationAction){
//                        Button("Cancel", systemImage: "xmark"){
//                            dismiss()
//                        }
//                    }
//                }
                
                
                // Bottom Action Bar
                VStack {
                    Spacer()
                    HStack(spacing: 40) {
                        actionButton(icon: "folder", action: {})
                        
                        // Main Action (e.g. Edit or Favorite) - Central Button
                        Button(action: {}) {
                            Image(systemName: "heart.fill")
                                .font(.system(size: 24))
                                .foregroundColor(.white)
                                .frame(width: 64, height: 64)
                                .background(Color.primary)
                                .clipShape(Circle())
                                .shadow(color: Color.primary.opacity(0.4), radius: 10, x: 0, y: 5)
                        }
                        
                        actionButton(icon: "trash", action: onDelete, isDestructive: true)
                    }
                    .padding(.horizontal, 30)
                    .padding(.bottom, 16)
      
                }
            }
           
        
 
    }
    
    private func detailItem(icon: String, title: String, value: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon) // Using system names for now, might need custom icons
                .font(.system(size: 18))
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
                //.background(Color.secondaryBackground)
                //.clipShape(Circle())
        }
    }
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM dd, yyyy"
        return formatter
    }
}

#Preview {
    @Previewable @Namespace var namespace
    
    // Create a temporary file URL for preview
    let documentsPath = FileManager.default.temporaryDirectory
    let imageURL = documentsPath.appendingPathComponent("preview_img.jpg")
    
    // Save img1 from asset catalog to temporary location for preview
    if let image = UIImage(named: "img1"), let data = image.jpegData(compressionQuality: 1.0) {
        try? data.write(to: imageURL)
    }
    
    let sampleAsset = PhotoAsset(
        originalURL: imageURL,
        previewURL: imageURL,
        thumbnailURL: imageURL,
        filterName: "Cinematic",
        lens: "24mm",
        iso: 200,
        aperture: 1.8,
        shutterSpeed: "1/125s",
        locationDescription: "San Francisco, CA",
        capturedAt: Date()
    )
    
    return GalleryDetailView(
        asset: sampleAsset,
        namespace: namespace,
        onDelete: {
            print("Delete tapped")
        }
    )
}
