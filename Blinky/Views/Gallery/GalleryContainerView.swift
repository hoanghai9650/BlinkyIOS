//
//  GalleryContainerView.swift
//  Blinky
//
//  Created by Codex.
//

import SwiftUI

enum GalleryTab: Int, Identifiable, CaseIterable {
    case gallery
    case album
    
    var id: Int { rawValue }
    
    var icon: String {
        switch self {
        case .gallery: return "square.grid.2x2"
        case .album: return "folder"
        }
    }
}

struct GalleryContainerView: View {
    var onCameraRequest: () -> Void = {}
    @State private var selection: GalleryTab = .gallery
    @State private var focusedAsset: PhotoAsset?
    @Namespace private var animation
    @Namespace private var namespaceTransition
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // Content
            Group {
                switch selection {
                case .gallery:
                    GalleryView(focusedAsset: $focusedAsset, namespace: animation)
                    
                case .album:
                    FolderView()
                }
            }
            
            // Custom Tab Bar
            customTabBar
                .opacity(focusedAsset == nil ? 1 : 0)
                .offset(y: focusedAsset == nil ? 0 : 100)
                .animation(.spring(response: 0.35, dampingFraction: 0.9), value: focusedAsset)
        }
    }
    
    private var customTabBar: some View {
        ZStack{
            HStack(spacing: 0) {
            Spacer()
            // Center - Gallery and Album icons
        
                    HStack(spacing: 16) {
                        tabButton(.gallery)
                        tabButton(.album)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 4)
                    .glassEffect(.regular.interactive())
//                    .background(
//                        .ultraThinMaterial,
//                        in: Capsule()
//                    )
                

            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 32)
            // Camera button - positioned to the right of center capsule
            Button {
                onCameraRequest()
            }
            label: {
                Image(systemName: "camera.fill")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 46, height: 46)
//                    .background(
//                        Circle()
//                            .fill(Color(.sRGB, red: 217/255, green: 93/255, blue: 61/255, opacity: 0.8))
//                    )
                    .glassEffect(.regular.interactive().tint(Color(.sRGB, red: 217/255, green: 93/255, blue: 61/255, opacity: 0.8)))
            }
            
            .padding(.leading, 16)
            .padding(.bottom, 32)
            .offset(x:100)
            
            
        }
        
    }
    
    private func tabButton(_ tab: GalleryTab) -> some View {
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                selection = tab
            }
            if tab != .gallery {
                focusedAsset = nil
            }
        } label: {
            Image(systemName: tab.icon)
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(
                    selection == tab
                        ? Color(.sRGB, red: 245/255, green: 245/255, blue: 237/255, opacity: 1)
                        : Color(.sRGB, red: 245/255, green: 245/255, blue: 237/255, opacity: 0.4)
                )
                .frame(width: 42, height: 42)
        }
    }
}

#Preview {
    GalleryContainerView()
}
