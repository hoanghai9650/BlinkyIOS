//
//  FolderView.swift
//  Blinky
//
//  Created by Codex.
//

import SwiftUI

struct FolderView: View {
    @State private var folders: [GalleryFolder] = GalleryFolder.sampleFolders
    
    var body: some View {
        List {
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
                        Text("\(folder.count) photos")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .foregroundColor(.secondary)
                        .font(.footnote.bold())
                }
                .padding(.vertical, 8)
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Folders")
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
