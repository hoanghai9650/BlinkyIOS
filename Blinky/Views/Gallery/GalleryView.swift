//
//  GalleryView.swift
//  Blinky
//
//  Created by Codex.
//

import SwiftUI
import SwiftData
import UIKit

struct GalleryView: View {
    @Binding var focusedAsset: PhotoAsset?
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \PhotoAsset.capturedAt, order: .reverse) private var assets: [PhotoAsset]
    @StateObject private var viewModel = GalleryViewModel()
    let namespace: Namespace.ID
    
    
    init(focusedAsset: Binding<PhotoAsset?>, namespace: Namespace.ID) {
        self._focusedAsset = focusedAsset
        self.namespace = namespace
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(.sRGB, red: 35/255, green: 38/255, blue: 40/255, opacity: 1)
                    .ignoresSafeArea()
                
                VStack(alignment: .leading, spacing: 0) {
                    // Header
                    GlassEffectContainer(spacing: 24){
                       HStack {
                           Spacer()
                                   HStack(spacing: 24) {
                                       if viewModel.isSelectionMode {
                                           Image(systemName: "trash")
                                               .frame(width: 42,height: 42)
                                               .font(.system(size: 16))
                                               .glassEffect(.regular.interactive())
                                               .glassEffectID("trash", in: namespace)
                                               .onTapGesture {
//                                                   viewModel.deleteSelected
                                               }
                                       }
                                       Button {
                                           withAnimation{
                                               viewModel.toggleSelectionMode()
                                               if !viewModel.isSelectionMode {
                                                   focusedAsset = nil
                                               }
                                           }
                                           
                                       } label: {
                                           Text(viewModel.isSelectionMode ? "Done" : "Select")
                                               .font(.system(size: 16, weight: .medium))
                                               .foregroundColor(Color(.sRGB, red: 245/255, green: 245/255, blue: 237/255, opacity: 1))
                                               .padding(.horizontal, 24)
                                               .padding(.vertical, 12)
                                               .glassEffect(.regular.interactive())
                                               .glassEffectID("button", in: namespace)
                                               
                                       }
                                       
                                }
                           }
                    }.padding(.horizontal, 16)
                         
                    
                    ScrollView(showsIndicators: false) {
                        VStack(alignment: .leading, spacing: 8) {
                            galleryGrid
                        }
                    }
                }
                
            }
  
        }
    }
    
   
        
    
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM. yyyy"
        return formatter.string(from: Date())
    }
    
    private var galleryGrid: some View {
        let columns = Array(repeating: GridItem(.flexible()), count: 3)
        
  
        return LazyVGrid(columns: columns, spacing: 12) {
            ForEach(assets){ asset in
                let isFocused = focusedAsset?.id == asset.id
                GalleryTile(
                    asset: asset,
                    isSelectionMode: viewModel.isSelectionMode,
                    isSelected: viewModel.isSelected(asset),
                    isFocused: isFocused,
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
                .onTapGesture {
                    if viewModel.isSelectionMode {
                        viewModel.toggleSelection(for: asset)
                    } else {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            focusedAsset = asset
                        }
                    }
                }
            }
          
        }
        .padding(.top, 16)
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
    
    var body: some View {
        // Use previewURL for consistent image quality with detail view
        let image = PhotoImageProvider.image(at: asset.previewURL)
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
//                    .shadow(
//                        color: Color(.sRGB, red: 245/255, green: 245/255, blue: 237/255, opacity: 0.15),
//                        radius: 8,
//                        x: 2,
//                        y: 2
//                    )
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
                Button(role: .destructive, action: onDelete) {
                    Image(systemName: "trash")
                        .font(.system(size: 16))
                        .foregroundColor(.white)
                        .padding(8)
                }
                .buttonStyle(.borderedProminent)
                .tint(.red)
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

#Preview {
    ContentView()
}

