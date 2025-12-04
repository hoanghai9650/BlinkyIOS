//
//  FolderView.swift
//  Blinky
//
//  Created by Codex.
//

import SwiftUI

struct FolderView: View {
    @State private var folders: [GalleryFolder] = GalleryFolder.sampleFolders
    @State private var isScrolled: Bool = false
    @Binding var isScrolledToBottom: Bool
    let safeArea: EdgeInsets
    
    var body: some View {
        ZStack(alignment: .top) {
            Color.background.ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    // Spacer for header
                    Color.clear.frame(height: safeArea.top + 44)
                    
                    LazyVStack(spacing: 0) {
                        ForEach(folders) { folder in
                            HStack(spacing: 16) {
                                Image(systemName: folder.icon)
                                    .font(.title3)
                                    .frame(width: 44, height: 44)
                                    .background(RoundedRectangle(cornerRadius: 12).fill(folder.tint.opacity(0.2)))
                                    .foregroundColor(folder.tint)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(folder.name)
                                        .font(.headline)
                                        .foregroundColor(Color.text)
                                    Text("\(folder.count) photos")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.secondary)
                                    .font(.footnote.bold())
                            }
                            .padding(.vertical, 12)
                            .padding(.horizontal, 16)
                        }
                    }
                    
                    // Bottom spacer for tab bar
                    Color.clear.frame(height: safeArea.bottom + 80)
                }
            }
            .onScrollGeometryChange(for: Bool.self) { geometry in
                geometry.contentOffset.y > 0
            } action: { _, isPastTop in
                withAnimation(.easeInOut(duration: 0.2)) {
                    isScrolled = isPastTop
                }
            }
            .onScrollGeometryChange(for: Bool.self) { geometry in
                let maxOffset = geometry.contentSize.height - geometry.containerSize.height
                return geometry.contentOffset.y < maxOffset - 10
            } action: { _, notAtBottom in
                withAnimation(.easeInOut(duration: 0.2)) {
                    isScrolledToBottom = notAtBottom
                }
            }
            
            // Header
            ScrollableHeader(
                safeAreaTop: safeArea.top,
                isScrolled: isScrolled
            ) {
                Button {
                    // Add folder action
                } label: {
                    Image(systemName: "folder.badge.plus")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(Color.text)
                }
            }
        }
    }
}

struct GalleryFolder: Identifiable {
    let id = UUID()
    let name: String
    let count: Int
    let icon: String
    let tint: Color
    
    static let sampleFolders: [GalleryFolder] = [
        .init(name: "Recent Shoots", count: 42, icon: "sparkles.square.fill", tint: .orange),
        .init(name: "Portraits", count: 18, icon: "person.crop.rectangle.stack", tint: .pink),
        .init(name: "Travel", count: 63, icon: "airplane", tint: .blue),
        .init(name: "Night Mode", count: 24, icon: "moon.stars.fill", tint: .indigo)
    ]
}

#Preview {
    @Previewable @State var isScrolledToBottom = true
    FolderView(
        isScrolledToBottom: $isScrolledToBottom,
        safeArea: EdgeInsets(top: 59, leading: 0, bottom: 34, trailing: 0)
    )
}
