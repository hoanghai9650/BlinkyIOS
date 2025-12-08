//
//  AsyncPhotoImage.swift
//  Blinky
//
//  Created by Codex.
//

import SwiftUI

/// An async image view that loads photos from file system with caching
struct AsyncPhotoImage: View {
    let url: URL
    let contentMode: ContentMode
    
    @State private var image: UIImage?
    @State private var isLoading = true
    
    init(url: URL, contentMode: ContentMode = .fill) {
        self.url = url
        self.contentMode = contentMode
        // Try to get from cache synchronously first
        self._image = State(initialValue: PhotoImageProvider.image(at: url))
        self._isLoading = State(initialValue: PhotoImageProvider.image(at: url) == nil)
    }
    
    var body: some View {
        Group {
            if let image {
                // Use Image(uiImage:) for local files - AsyncImage only works with network URLs
                Image(uiImage: image)
                    
                    .resizable()
                    .aspectRatio(contentMode: contentMode)
            } else if isLoading {
                Rectangle()
                    .fill(Color.gray.opacity(0.15))
            } else {
                Rectangle()
                    .fill(Color.gray.opacity(0.25))
            }
        }
        .task(id: url) {
            guard image == nil else { return }
            if let loaded = await PhotoImageProvider.imageAsync(at: url) {
                withAnimation(.easeIn(duration: 0.15)) {
                    image = loaded  
                }
            }
            isLoading = false
        }
    }
}
